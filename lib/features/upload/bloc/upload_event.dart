part of 'upload_bloc.dart';

/// Base class for upload events.
abstract class UploadEvent extends Equatable {
  const UploadEvent();

  @override
  List<Object?> get props => [];
}

/// Event to submit a job from a URL.
class SubmitUrlJobEvent extends UploadEvent {
  final String url;
  final String? title;
  final String? description;
  final String? transcriptionEngine;
  final int? segmentDuration; // Chunk duration in seconds: 60, 180, 300, 600, 900, 1800, 3600
  final bool isLive; // Whether this is a live stream capture
  final int? captureSeconds; // Duration to capture from live stream (60-3600)

  const SubmitUrlJobEvent({
    required this.url,
    this.title,
    this.description,
    this.transcriptionEngine,
    this.segmentDuration,
    this.isLive = false,
    this.captureSeconds,
  });

  @override
  List<Object?> get props => [url, title, description, transcriptionEngine, segmentDuration, isLive, captureSeconds];
}

/// Event to submit a job from a file upload.
class SubmitFileJobEvent extends UploadEvent {
  final String? filePath;
  final Uint8List? fileBytes;
  final String fileName;
  final String? title;
  final String? description;
  final String? transcriptionEngine;
  final int? segmentDuration; // Chunk duration in seconds: 60, 180, 300, 600, 900, 1800, 3600

  const SubmitFileJobEvent({
    this.filePath,
    this.fileBytes,
    required this.fileName,
    this.title,
    this.description,
    this.transcriptionEngine,
    this.segmentDuration,
  });

  @override
  List<Object?> get props => [
        filePath,
        fileBytes,
        fileName,
        title,
        description,
        transcriptionEngine,
        segmentDuration,
      ];
}

/// Event to reset the upload state.
class ResetUploadEvent extends UploadEvent {
  const ResetUploadEvent();
}
