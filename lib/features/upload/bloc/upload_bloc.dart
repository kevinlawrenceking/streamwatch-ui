import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mime/mime.dart';
import '../../../data/models/job_model.dart';
import '../../../data/sources/job_data_source.dart';
import '../../../data/sources/upload_data_source.dart';
import '../../../shared/errors/failures/failure.dart';

part 'upload_event.dart';
part 'upload_state.dart';

/// BLoC for managing the upload/job creation feature.
///
/// File uploads use presigned S3 URLs to bypass API Gateway's 10MB limit.
/// URL uploads go directly to the API.
class UploadBloc extends Bloc<UploadEvent, UploadState> {
  final IJobDataSource _jobDataSource;
  final IUploadDataSource _uploadDataSource;

  UploadBloc({
    required IJobDataSource jobDataSource,
    required IUploadDataSource uploadDataSource,
  })  : _jobDataSource = jobDataSource,
        _uploadDataSource = uploadDataSource,
        super(const UploadInitial()) {
    on<SubmitUrlJobEvent>(_onSubmitUrlJob);
    on<SubmitFileJobEvent>(_onSubmitFileJob);
    on<ResetUploadEvent>(_onResetUpload);
  }

  /// Handle URL job submission (unchanged - goes directly to API).
  Future<void> _onSubmitUrlJob(
    SubmitUrlJobEvent event,
    Emitter<UploadState> emit,
  ) async {
    emit(const UploadSubmitting());

    final result = await _jobDataSource.createJobFromUrl(
      url: event.url,
      title: event.title,
      description: event.description,
      celebrities: event.celebrities,
      transcriptionEngine: event.transcriptionEngine,
      segmentDuration: event.segmentDuration,
      isLive: event.isLive,
      captureSeconds: event.captureSeconds,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(UploadError(failure)),
      (job) => emit(UploadSuccess(job)),
    );
  }

  /// Handle file job submission using presigned S3 upload.
  ///
  /// Flow:
  /// 1. Request presigned URL from API
  /// 2. Upload file directly to S3
  /// 3. Call complete endpoint to create job
  Future<void> _onSubmitFileJob(
    SubmitFileJobEvent event,
    Emitter<UploadState> emit,
  ) async {
    // Validate we have file bytes
    if (event.fileBytes == null || event.fileBytes!.isEmpty) {
      emit(UploadError(
        const ValidationFailure(message: 'No file data provided'),
      ));
      return;
    }

    final fileBytes = event.fileBytes!;
    final fileName = event.fileName;
    final fileSize = fileBytes.length;

    // Determine content type
    final contentType = _getContentType(fileName);
    if (contentType == null) {
      emit(UploadError(
        ValidationFailure(message: 'Unsupported file type: $fileName'),
      ));
      return;
    }

    // Phase 1: Request presigned URL
    emit(const FileUploadInProgress(
      phase: UploadPhase.requestingPresign,
    ));

    final presignResult = await _uploadDataSource.requestPresignedUrl(
      filename: fileName,
      contentType: contentType,
      bytes: fileSize,
      title: event.title,
      description: event.description,
      celebrities: event.celebrities,
      transcriptionEngine: event.transcriptionEngine,
      segmentDuration: event.segmentDuration,
    );

    if (isClosed) return;

    // Handle presign failure
    if (presignResult.isLeft()) {
      presignResult.fold(
        (failure) => emit(UploadError(failure, canRetry: true)),
        (_) {},
      );
      return;
    }

    final presignedUpload = presignResult.getOrElse(() => throw StateError('Unreachable'));

    // Phase 2: Upload to S3
    emit(FileUploadInProgress(
      phase: UploadPhase.uploadingToS3,
      uploadId: presignedUpload.uploadId,
      totalBytes: fileSize,
      bytesUploaded: 0,
    ));

    final s3Result = await _uploadDataSource.uploadToS3(
      presignedUrl: presignedUpload.url,
      headers: presignedUpload.headers,
      fileBytes: fileBytes,
      onProgress: (bytesSent, totalBytes) {
        if (!isClosed) {
          // Note: Due to how http package works, this may not fire incrementally
          // but we emit the final state after completion anyway
        }
      },
    );

    if (isClosed) return;

    // Handle S3 upload failure - DO NOT call finalize
    if (s3Result.isLeft()) {
      s3Result.fold(
        (failure) => emit(UploadError(
          failure,
          canRetry: true,
          uploadId: presignedUpload.uploadId,
        )),
        (_) {},
      );
      return;
    }

    // Phase 3: Complete upload and create job
    emit(FileUploadInProgress(
      phase: UploadPhase.finalizing,
      uploadId: presignedUpload.uploadId,
      totalBytes: fileSize,
      bytesUploaded: fileSize,
    ));

    final completeResult = await _uploadDataSource.completeUpload(
      uploadId: presignedUpload.uploadId,
    );

    if (isClosed) return;

    completeResult.fold(
      (failure) => emit(UploadError(
        failure,
        canRetry: false, // S3 upload succeeded, finalize failed - complex retry
        uploadId: presignedUpload.uploadId,
      )),
      (job) => emit(UploadSuccess(job)),
    );
  }

  /// Reset upload state to initial.
  void _onResetUpload(
    ResetUploadEvent event,
    Emitter<UploadState> emit,
  ) {
    emit(const UploadInitial());
  }

  /// Get MIME content type for a filename.
  String? _getContentType(String filename) {
    // Try to get from mime package
    final mimeType = lookupMimeType(filename);
    if (mimeType != null) {
      return mimeType;
    }

    // Fallback for common video/audio types
    final ext = filename.toLowerCase().split('.').last;
    const supportedTypes = {
      'mp4': 'video/mp4',
      'm4v': 'video/mp4',
      'mov': 'video/quicktime',
      'avi': 'video/x-msvideo',
      'mkv': 'video/x-matroska',
      'webm': 'video/webm',
      'mpeg': 'video/mpeg',
      'mpg': 'video/mpeg',
      '3gp': 'video/3gpp',
      'm4a': 'audio/mp4',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'aac': 'audio/aac',
    };

    return supportedTypes[ext];
  }
}
