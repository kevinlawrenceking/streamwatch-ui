part of 'detection_bloc.dart';

abstract class DetectionState extends Equatable {
  const DetectionState();
  @override
  List<Object?> get props => [];
}

class DetectionInitial extends DetectionState {
  const DetectionInitial();
}

class DetectionLoading extends DetectionState {
  const DetectionLoading();
}

class DetectionLoaded extends DetectionState {
  final List<DetectionRun> runs;

  /// Per-run actions cache. Populated lazily on row expand
  /// (`LoadDetectionActionsEvent`); subsequent expand-collapse cycles
  /// re-use the cached list without re-fetching (Plan-Lock #5 alpha).
  final Map<String, List<DetectionAction>> actionsByRunId;

  final String? statusFilter;
  final String? episodeFilter;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  final bool isMutating;
  final bool isBatchTriggering;
  final String? lastActionError;
  final String? lastActionMessage;

  /// Per-item results from the most recent batch-trigger 207 response.
  /// Non-null -> view layer opens BatchResultDialog. Cleared by
  /// [BatchResultAcknowledgedEvent] (which also dispatches
  /// LoadDetectionRunsEvent for refetch).
  final List<BatchTriggerItemResult>? lastBatchResult;

  const DetectionLoaded({
    required this.runs,
    this.actionsByRunId = const <String, List<DetectionAction>>{},
    this.statusFilter,
    this.episodeFilter,
    this.createdFrom,
    this.createdTo,
    this.isMutating = false,
    this.isBatchTriggering = false,
    this.lastActionError,
    this.lastActionMessage,
    this.lastBatchResult,
  });

  DetectionLoaded copyWith({
    List<DetectionRun>? runs,
    Map<String, List<DetectionAction>>? actionsByRunId,
    String? statusFilter,
    String? episodeFilter,
    DateTime? createdFrom,
    DateTime? createdTo,
    bool? isMutating,
    bool? isBatchTriggering,
    String? lastActionError,
    String? lastActionMessage,
    List<BatchTriggerItemResult>? lastBatchResult,
    bool clearLastActionError = false,
    bool clearLastActionMessage = false,
    bool clearLastBatchResult = false,
  }) {
    return DetectionLoaded(
      runs: runs ?? this.runs,
      actionsByRunId: actionsByRunId ?? this.actionsByRunId,
      statusFilter: statusFilter ?? this.statusFilter,
      episodeFilter: episodeFilter ?? this.episodeFilter,
      createdFrom: createdFrom ?? this.createdFrom,
      createdTo: createdTo ?? this.createdTo,
      isMutating: isMutating ?? this.isMutating,
      isBatchTriggering: isBatchTriggering ?? this.isBatchTriggering,
      lastActionError: clearLastActionError
          ? null
          : (lastActionError ?? this.lastActionError),
      lastActionMessage: clearLastActionMessage
          ? null
          : (lastActionMessage ?? this.lastActionMessage),
      lastBatchResult: clearLastBatchResult
          ? null
          : (lastBatchResult ?? this.lastBatchResult),
    );
  }

  @override
  List<Object?> get props => [
        runs,
        actionsByRunId,
        statusFilter,
        episodeFilter,
        createdFrom,
        createdTo,
        isMutating,
        isBatchTriggering,
        lastActionError,
        lastActionMessage,
        lastBatchResult,
      ];
}

class DetectionError extends DetectionState {
  final String message;
  const DetectionError(this.message);
  @override
  List<Object?> get props => [message];
}
