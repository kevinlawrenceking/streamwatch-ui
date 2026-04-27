part of 'detection_bloc.dart';

abstract class DetectionEvent extends Equatable {
  const DetectionEvent();
  @override
  List<Object?> get props => [];
}

class LoadDetectionRunsEvent extends DetectionEvent {
  final String? status;
  final String? episodeId;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  const LoadDetectionRunsEvent({
    this.status,
    this.episodeId,
    this.createdFrom,
    this.createdTo,
  });
  @override
  List<Object?> get props => [status, episodeId, createdFrom, createdTo];
}

class DetectionFilterChangedEvent extends DetectionEvent {
  final String? status;
  final String? episodeId;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  const DetectionFilterChangedEvent({
    this.status,
    this.episodeId,
    this.createdFrom,
    this.createdTo,
  });
  @override
  List<Object?> get props => [status, episodeId, createdFrom, createdTo];
}

class LoadDetectionActionsEvent extends DetectionEvent {
  final String runId;
  const LoadDetectionActionsEvent(this.runId);
  @override
  List<Object?> get props => [runId];
}

class TriggerDetectionEvent extends DetectionEvent {
  final String episodeId;
  const TriggerDetectionEvent(this.episodeId);
  @override
  List<Object?> get props => [episodeId];
}

class BatchTriggerEvent extends DetectionEvent {
  final List<String> episodeIds;
  const BatchTriggerEvent(this.episodeIds);
  @override
  List<Object?> get props => [episodeIds];
}

/// Dispatched by the view layer when the user closes BatchResultDialog.
/// Clears `lastBatchResult` and dispatches `LoadDetectionRunsEvent` for
/// auto-refetch (toast L-6 close path).
class BatchResultAcknowledgedEvent extends DetectionEvent {
  const BatchResultAcknowledgedEvent();
}

/// Disambiguated per §30.10 (sibling: WatchlistErrorAcknowledged,
/// JobsErrorAcknowledged).
class DetectionErrorAcknowledged extends DetectionEvent {
  const DetectionErrorAcknowledged();
}
