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
  final String? celebrities; // Comma/newline separated celebrity names
  final String? transcriptionEngine;
  final int? segmentDuration; // Chunk duration in seconds: 60, 180, 300, 600, 900, 1800, 3600
  final bool isLive; // Whether this is a live stream capture
  final int? captureSeconds; // Duration to capture from live stream (60-3600)
  final String? collectionId; // Optional: assign to a collection

  const SubmitUrlJobEvent({
    required this.url,
    this.title,
    this.description,
    this.celebrities,
    this.transcriptionEngine,
    this.segmentDuration,
    this.isLive = false,
    this.captureSeconds,
    this.collectionId,
  });

  @override
  List<Object?> get props => [url, title, description, celebrities, transcriptionEngine, segmentDuration, isLive, captureSeconds, collectionId];
}

/// Event to submit a job from a file upload.
class SubmitFileJobEvent extends UploadEvent {
  final String? filePath;
  final Uint8List? fileBytes;
  final String fileName;
  final String? title;
  final String? description;
  final String? celebrities; // Comma/newline separated celebrity names
  final String? transcriptionEngine;
  final int? segmentDuration; // Chunk duration in seconds: 60, 180, 300, 600, 900, 1800, 3600
  final String? collectionId; // Optional: assign to a collection

  const SubmitFileJobEvent({
    this.filePath,
    this.fileBytes,
    required this.fileName,
    this.title,
    this.description,
    this.celebrities,
    this.transcriptionEngine,
    this.segmentDuration,
    this.collectionId,
  });

  @override
  List<Object?> get props => [
        filePath,
        fileBytes,
        fileName,
        title,
        description,
        celebrities,
        transcriptionEngine,
        segmentDuration,
        collectionId,
      ];
}

/// Event to reset the upload state.
class ResetUploadEvent extends UploadEvent {
  const ResetUploadEvent();
}
