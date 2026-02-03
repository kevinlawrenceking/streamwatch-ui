part of 'upload_bloc.dart';

/// Upload progress phase for presigned uploads.
enum UploadPhase {
  /// Requesting presigned URL from API
  requestingPresign,
  /// Uploading file to S3
  uploadingToS3,
  /// Finalizing upload and creating job
  finalizing,
}

/// Base class for upload states.
abstract class UploadState extends Equatable {
  const UploadState();

  @override
  List<Object?> get props => [];
}

/// Initial state - ready for input.
class UploadInitial extends UploadState {
  const UploadInitial();
}

/// State while submitting URL job (simple, no phases).
class UploadSubmitting extends UploadState {
  const UploadSubmitting();
}

/// State while uploading file via presigned S3 flow.
class FileUploadInProgress extends UploadState {
  final UploadPhase phase;
  final String? uploadId;
  final int? bytesUploaded;
  final int? totalBytes;

  const FileUploadInProgress({
    required this.phase,
    this.uploadId,
    this.bytesUploaded,
    this.totalBytes,
  });

  @override
  List<Object?> get props => [phase, uploadId, bytesUploaded, totalBytes];

  /// Human-readable status message.
  String get statusMessage {
    switch (phase) {
      case UploadPhase.requestingPresign:
        return 'Preparing upload...';
      case UploadPhase.uploadingToS3:
        if (bytesUploaded != null && totalBytes != null && totalBytes! > 0) {
          final pct = (bytesUploaded! / totalBytes! * 100).toStringAsFixed(0);
          return 'Uploading to S3... $pct%';
        }
        return 'Uploading to S3...';
      case UploadPhase.finalizing:
        return 'Creating job...';
    }
  }
}

/// State when job was successfully created.
class UploadSuccess extends UploadState {
  final JobModel job;

  const UploadSuccess(this.job);

  @override
  List<Object?> get props => [job];
}

/// Error state when job creation failed.
class UploadError extends UploadState {
  final Failure failure;
  /// Whether the error occurred before S3 upload (safe to retry from start)
  final bool canRetry;
  /// Optional upload ID if presign succeeded but S3/finalize failed
  final String? uploadId;

  const UploadError(this.failure, {this.canRetry = true, this.uploadId});

  @override
  List<Object?> get props => [failure, canRetry, uploadId];
}
