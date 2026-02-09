import 'package:equatable/equatable.dart';

/// Events for the home BLoC.
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Load jobs with optional filters.
class LoadJobsEvent extends HomeEvent {
  final String? searchQuery;
  final String? statusFilter;
  final int limit;

  const LoadJobsEvent({
    this.searchQuery,
    this.statusFilter,
    this.limit = 300,
  });

  @override
  List<Object?> get props => [searchQuery, statusFilter, limit];
}

/// Refresh the jobs list.
class RefreshJobsEvent extends HomeEvent {
  const RefreshJobsEvent();
}

/// Update search query (for debouncing).
class SearchQueryChangedEvent extends HomeEvent {
  final String query;

  const SearchQueryChangedEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Update status filter.
class StatusFilterChangedEvent extends HomeEvent {
  final String? status;

  const StatusFilterChangedEvent(this.status);

  @override
  List<Object?> get props => [status];
}

/// Delete a job (soft delete).
class DeleteJobEvent extends HomeEvent {
  final String jobId;

  const DeleteJobEvent(this.jobId);

  @override
  List<Object?> get props => [jobId];
}

/// Toggle flag status of a job.
class ToggleFlagJobEvent extends HomeEvent {
  final String jobId;
  final bool isFlagged;
  final String? flagNote;

  const ToggleFlagJobEvent({
    required this.jobId,
    required this.isFlagged,
    this.flagNote,
  });

  @override
  List<Object?> get props => [jobId, isFlagged, flagNote];
}

/// Pause a job.
class PauseJobEvent extends HomeEvent {
  final String jobId;

  const PauseJobEvent(this.jobId);

  @override
  List<Object?> get props => [jobId];
}

/// Resume a paused job.
class ResumeJobEvent extends HomeEvent {
  final String jobId;

  const ResumeJobEvent(this.jobId);

  @override
  List<Object?> get props => [jobId];
}

/// Cancel a processing or queued job.
class CancelJobEvent extends HomeEvent {
  final String jobId;

  const CancelJobEvent(this.jobId);

  @override
  List<Object?> get props => [jobId];
}

/// Load videos from a specific collection.
class LoadCollectionVideosEvent extends HomeEvent {
  final String collectionId;

  const LoadCollectionVideosEvent(this.collectionId);

  @override
  List<Object?> get props => [collectionId];
}

/// Toggle view mode between list and grid.
class ToggleViewModeEvent extends HomeEvent {
  const ToggleViewModeEvent();
}
