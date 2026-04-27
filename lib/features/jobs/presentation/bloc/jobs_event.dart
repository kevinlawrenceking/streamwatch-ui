part of 'jobs_bloc.dart';

abstract class JobsEvent extends Equatable {
  const JobsEvent();
  @override
  List<Object?> get props => [];
}

class LoadJobsEvent extends JobsEvent {
  final String? status;
  final String? podcastId;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  const LoadJobsEvent({
    this.status,
    this.podcastId,
    this.createdFrom,
    this.createdTo,
  });
  @override
  List<Object?> get props => [status, podcastId, createdFrom, createdTo];
}

class JobsFilterChangedEvent extends JobsEvent {
  final String? status;
  final String? podcastId;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  const JobsFilterChangedEvent({
    this.status,
    this.podcastId,
    this.createdFrom,
    this.createdTo,
  });
  @override
  List<Object?> get props => [status, podcastId, createdFrom, createdTo];
}

class RetryJobEvent extends JobsEvent {
  final String jobId;
  const RetryJobEvent(this.jobId);
  @override
  List<Object?> get props => [jobId];
}

/// Disambiguated per §30.10 (sibling: WatchlistErrorAcknowledged,
/// DetectionErrorAcknowledged).
class JobsErrorAcknowledged extends JobsEvent {
  const JobsErrorAcknowledged();
}
