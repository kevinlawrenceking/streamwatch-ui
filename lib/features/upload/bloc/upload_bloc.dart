import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/job_model.dart';
import '../../../data/sources/job_data_source.dart';
import '../../../shared/errors/failures/failure.dart';

part 'upload_event.dart';
part 'upload_state.dart';

/// BLoC for managing the upload/job creation feature.
class UploadBloc extends Bloc<UploadEvent, UploadState> {
  final IJobDataSource _dataSource;

  UploadBloc({required IJobDataSource dataSource})
      : _dataSource = dataSource,
        super(const UploadInitial()) {
    on<SubmitUrlJobEvent>(_onSubmitUrlJob);
    on<SubmitFileJobEvent>(_onSubmitFileJob);
    on<ResetUploadEvent>(_onResetUpload);
  }

  Future<void> _onSubmitUrlJob(
    SubmitUrlJobEvent event,
    Emitter<UploadState> emit,
  ) async {
    emit(const UploadSubmitting());

    final result = await _dataSource.createJobFromUrl(
      url: event.url,
      title: event.title,
      description: event.description,
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

  Future<void> _onSubmitFileJob(
    SubmitFileJobEvent event,
    Emitter<UploadState> emit,
  ) async {
    emit(const UploadSubmitting());

    final result = await _dataSource.createJobFromFile(
      filePath: event.filePath,
      fileBytes: event.fileBytes,
      fileName: event.fileName,
      title: event.title,
      description: event.description,
      transcriptionEngine: event.transcriptionEngine,
      segmentDuration: event.segmentDuration,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(UploadError(failure)),
      (job) => emit(UploadSuccess(job)),
    );
  }

  void _onResetUpload(
    ResetUploadEvent event,
    Emitter<UploadState> emit,
  ) {
    emit(const UploadInitial());
  }
}
