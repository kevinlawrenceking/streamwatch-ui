part of 'job_detail_bloc.dart';

/// Base class for job detail states.
abstract class JobDetailState extends Equatable {
  const JobDetailState();

  @override
  List<Object?> get props => [];
}

/// Initial state before job is loaded.
class JobDetailInitial extends JobDetailState {
  const JobDetailInitial();
}

/// Loading state while fetching job details.
class JobDetailLoading extends JobDetailState {
  const JobDetailLoading();
}

/// Types of job actions that can be in-flight.
enum JobDetailActionType { delete, flag, pause, resume }

/// State when job details are loaded.
class JobDetailLoaded extends JobDetailState {
  final JobModel job;
  final List<ChunkModel> chunks;
  final List<CelebrityModel> celebrities;

  /// Whether the BLoC is currently polling for updates
  final bool isPolling;

  /// Error message from polling (shown as non-blocking warning)
  final String? pollError;

  /// Action currently in-flight, if any.
  final JobDetailActionType? inFlightAction;

  /// Error message from last action (cleared on next action).
  final String? actionError;

  /// Success message from last action (cleared on next action).
  final String? actionSuccess;

  /// Whether the job was deleted (to trigger navigation back).
  final bool jobDeleted;

  const JobDetailLoaded({
    required this.job,
    required this.chunks,
    this.celebrities = const [],
    required this.isPolling,
    required this.pollError,
    this.inFlightAction,
    this.actionError,
    this.actionSuccess,
    this.jobDeleted = false,
  });

  JobDetailLoaded copyWith({
    JobModel? job,
    List<ChunkModel>? chunks,
    List<CelebrityModel>? celebrities,
    bool? isPolling,
    String? pollError,
    JobDetailActionType? inFlightAction,
    String? actionError,
    String? actionSuccess,
    bool? jobDeleted,
    bool clearInFlightAction = false,
    bool clearActionError = false,
    bool clearActionSuccess = false,
  }) {
    return JobDetailLoaded(
      job: job ?? this.job,
      chunks: chunks ?? this.chunks,
      celebrities: celebrities ?? this.celebrities,
      isPolling: isPolling ?? this.isPolling,
      // pollError needs explicit null handling since we want to clear it
      pollError: pollError,
      inFlightAction: clearInFlightAction ? null : (inFlightAction ?? this.inFlightAction),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      actionSuccess: clearActionSuccess ? null : (actionSuccess ?? this.actionSuccess),
      jobDeleted: jobDeleted ?? this.jobDeleted,
    );
  }

  @override
  List<Object?> get props => [
        job,
        chunks,
        celebrities,
        isPolling,
        pollError,
        inFlightAction,
        actionError,
        actionSuccess,
        jobDeleted,
      ];
}

/// Error state when loading fails.
class JobDetailError extends JobDetailState {
  final Failure failure;

  const JobDetailError(this.failure);

  @override
  List<Object?> get props => [failure];
}
