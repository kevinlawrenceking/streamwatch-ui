part of 'jobs_bloc.dart';

abstract class JobsState extends Equatable {
  const JobsState();
  @override
  List<Object?> get props => [];
}

class JobsInitial extends JobsState {
  const JobsInitial();
}

class JobsLoading extends JobsState {
  const JobsLoading();
}

class JobsLoaded extends JobsState {
  final List<PodcastJob> jobs;
  final String? statusFilter;
  final String? podcastFilter;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  final bool isMutating;
  final String? lastActionError;

  /// Success-toast field. Used by toast L-1 (`Retry queued for ${jobId}`).
  /// Cleared by [JobsErrorAcknowledged] alongside lastActionError.
  final String? lastActionMessage;

  const JobsLoaded({
    required this.jobs,
    this.statusFilter,
    this.podcastFilter,
    this.createdFrom,
    this.createdTo,
    this.isMutating = false,
    this.lastActionError,
    this.lastActionMessage,
  });

  JobsLoaded copyWith({
    List<PodcastJob>? jobs,
    String? statusFilter,
    String? podcastFilter,
    DateTime? createdFrom,
    DateTime? createdTo,
    bool? isMutating,
    String? lastActionError,
    String? lastActionMessage,
    bool clearLastActionError = false,
    bool clearLastActionMessage = false,
  }) {
    return JobsLoaded(
      jobs: jobs ?? this.jobs,
      statusFilter: statusFilter ?? this.statusFilter,
      podcastFilter: podcastFilter ?? this.podcastFilter,
      createdFrom: createdFrom ?? this.createdFrom,
      createdTo: createdTo ?? this.createdTo,
      isMutating: isMutating ?? this.isMutating,
      lastActionError: clearLastActionError
          ? null
          : (lastActionError ?? this.lastActionError),
      lastActionMessage: clearLastActionMessage
          ? null
          : (lastActionMessage ?? this.lastActionMessage),
    );
  }

  @override
  List<Object?> get props => [
        jobs,
        statusFilter,
        podcastFilter,
        createdFrom,
        createdTo,
        isMutating,
        lastActionError,
        lastActionMessage,
      ];
}

class JobsError extends JobsState {
  final String message;
  const JobsError(this.message);
  @override
  List<Object?> get props => [message];
}
