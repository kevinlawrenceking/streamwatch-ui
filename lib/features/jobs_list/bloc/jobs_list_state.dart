part of 'jobs_list_bloc.dart';

/// Base class for jobs list states.
abstract class JobsListState extends Equatable {
  const JobsListState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any jobs are loaded.
class JobsListInitial extends JobsListState {
  const JobsListInitial();
}

/// Loading state while fetching jobs.
class JobsListLoading extends JobsListState {
  const JobsListLoading();
}

/// State when jobs are successfully loaded.
class JobsListLoaded extends JobsListState {
  final List<JobModel> jobs;

  const JobsListLoaded(this.jobs);

  @override
  List<Object?> get props => [jobs];
}

/// State while refreshing (keeps current jobs visible).
class JobsListRefreshing extends JobsListState {
  final List<JobModel> jobs;

  const JobsListRefreshing(this.jobs);

  @override
  List<Object?> get props => [jobs];
}

/// Error state when loading fails.
class JobsListError extends JobsListState {
  final Failure failure;

  const JobsListError(this.failure);

  @override
  List<Object?> get props => [failure];
}
