part of 'jobs_list_bloc.dart';

/// Base class for jobs list events.
abstract class JobsListEvent extends Equatable {
  const JobsListEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load the initial jobs list.
class LoadJobsEvent extends JobsListEvent {
  final int limit;

  const LoadJobsEvent({this.limit = 20});

  @override
  List<Object?> get props => [limit];
}

/// Event to refresh the jobs list (e.g., pull-to-refresh).
class RefreshJobsEvent extends JobsListEvent {
  final int limit;

  const RefreshJobsEvent({this.limit = 20});

  @override
  List<Object?> get props => [limit];
}
