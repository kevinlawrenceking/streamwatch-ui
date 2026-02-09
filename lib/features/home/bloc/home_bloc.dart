import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/job_model.dart';
import '../../../data/sources/collection_data_source.dart';
import '../../../data/sources/job_data_source.dart';
import '../../../shared/errors/failures/failure.dart';
import 'home_event.dart';
import 'home_state.dart';

/// BLoC for the home screen with search and filter functionality.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final IJobDataSource _jobDataSource;
  final ICollectionDataSource? _collectionDataSource;

  HomeBloc({
    required IJobDataSource jobDataSource,
    ICollectionDataSource? collectionDataSource,
  })  : _jobDataSource = jobDataSource,
        _collectionDataSource = collectionDataSource,
        super(const HomeInitial()) {
    on<LoadJobsEvent>(_onLoadJobs);
    on<RefreshJobsEvent>(_onRefreshJobs);
    on<SearchQueryChangedEvent>(_onSearchQueryChanged);
    on<StatusFilterChangedEvent>(_onStatusFilterChanged);
    on<DeleteJobEvent>(_onDeleteJob);
    on<ToggleFlagJobEvent>(_onToggleFlagJob);
    on<PauseJobEvent>(_onPauseJob);
    on<ResumeJobEvent>(_onResumeJob);
    on<CancelJobEvent>(_onCancelJob);
    on<LoadCollectionVideosEvent>(_onLoadCollectionVideos);
    on<ToggleViewModeEvent>(_onToggleViewMode);
  }

  Future<void> _onLoadJobs(LoadJobsEvent event, Emitter<HomeState> emit) async {
    emit(const HomeLoading());

    // Pass status filter to API for server-side filtering
    final result = await _jobDataSource.getRecentJobs(
      limit: event.limit,
      status: event.statusFilter,
    );

    result.fold(
      (failure) => emit(HomeError(failure)),
      (jobs) {
        // Apply search query locally (status already filtered by server)
        final filteredJobs = _filterJobsBySearch(jobs, event.searchQuery ?? '');
        emit(HomeLoaded(
          jobs: jobs,
          filteredJobs: filteredJobs,
          searchQuery: event.searchQuery ?? '',
          statusFilter: event.statusFilter,
        ));
      },
    );
  }

  Future<void> _onRefreshJobs(
    RefreshJobsEvent event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    ViewMode viewMode = ViewMode.grid;

    if (currentState is HomeLoaded) {
      viewMode = currentState.viewMode;
      emit(HomeRefreshing(
        jobs: currentState.jobs,
        filteredJobs: currentState.filteredJobs,
        searchQuery: currentState.searchQuery,
        statusFilter: currentState.statusFilter,
        viewMode: viewMode,
      ));
    }

    String searchQuery = '';
    String? statusFilter;

    if (currentState is HomeLoaded) {
      searchQuery = currentState.searchQuery;
      statusFilter = currentState.statusFilter;
    } else if (currentState is HomeRefreshing) {
      searchQuery = currentState.searchQuery;
      statusFilter = currentState.statusFilter;
      viewMode = currentState.viewMode;
    }

    // Pass status filter to API for server-side filtering
    final result = await _jobDataSource.getRecentJobs(
      limit: 300,
      status: statusFilter,
    );

    result.fold(
      (failure) => emit(HomeError(failure)),
      (jobs) {
        // Apply search query locally (status already filtered by server)
        final filteredJobs = _filterJobsBySearch(jobs, searchQuery);
        emit(HomeLoaded(
          jobs: jobs,
          filteredJobs: filteredJobs,
          searchQuery: searchQuery,
          statusFilter: statusFilter,
          viewMode: viewMode,
        ));
      },
    );
  }

  void _onSearchQueryChanged(
    SearchQueryChangedEvent event,
    Emitter<HomeState> emit,
  ) {
    final currentState = state;
    if (currentState is HomeLoaded) {
      // Status already filtered by server, just apply search locally
      final filteredJobs = _filterJobsBySearch(currentState.jobs, event.query);
      emit(currentState.copyWith(
        searchQuery: event.query,
        filteredJobs: filteredJobs,
      ));
    }
  }

  Future<void> _onStatusFilterChanged(
    StatusFilterChangedEvent event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    final viewMode = currentState.viewMode;

    // Show loading state while fetching
    emit(HomeRefreshing(
      jobs: currentState.jobs,
      filteredJobs: currentState.filteredJobs,
      searchQuery: currentState.searchQuery,
      statusFilter: event.status,
      viewMode: viewMode,
    ));

    // Re-fetch from server with new status filter
    final result = await _jobDataSource.getRecentJobs(
      limit: 300,
      status: event.status,
    );

    result.fold(
      (failure) => emit(HomeError(failure)),
      (jobs) {
        final filteredJobs = _filterJobsBySearch(jobs, currentState.searchQuery);
        emit(HomeLoaded(
          jobs: jobs,
          filteredJobs: filteredJobs,
          searchQuery: currentState.searchQuery,
          statusFilter: event.status,
          viewMode: viewMode,
        ));
      },
    );
  }

  /// Delete a job (soft delete).
  Future<void> _onDeleteJob(
    DeleteJobEvent event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    // Set in-flight state
    final updatedInFlight = Map<String, JobActionType>.from(currentState.inFlightActions);
    updatedInFlight[event.jobId] = JobActionType.delete;
    emit(currentState.copyWith(
      inFlightActions: updatedInFlight,
      clearActionError: true,
      clearActionSuccess: true,
    ));

    final result = await _jobDataSource.deleteJob(event.jobId);

    result.fold(
      (failure) {
        // Remove from in-flight and show error
        final newInFlight = Map<String, JobActionType>.from(currentState.inFlightActions);
        newInFlight.remove(event.jobId);
        emit(currentState.copyWith(
          inFlightActions: newInFlight,
          actionError: _getErrorMessage(failure, 'delete'),
        ));
      },
      (_) {
        // Remove job from list on success
        final newJobs = currentState.jobs.where((j) => j.jobId != event.jobId).toList();
        final newFilteredJobs = currentState.filteredJobs.where((j) => j.jobId != event.jobId).toList();
        final newInFlight = Map<String, JobActionType>.from(currentState.inFlightActions);
        newInFlight.remove(event.jobId);

        emit(currentState.copyWith(
          jobs: newJobs,
          filteredJobs: newFilteredJobs,
          inFlightActions: newInFlight,
          actionSuccess: 'Job deleted',
        ));
      },
    );
  }

  /// Toggle flag status of a job.
  Future<void> _onToggleFlagJob(
    ToggleFlagJobEvent event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    // Set in-flight state
    final updatedInFlight = Map<String, JobActionType>.from(currentState.inFlightActions);
    updatedInFlight[event.jobId] = JobActionType.flag;
    emit(currentState.copyWith(
      inFlightActions: updatedInFlight,
      clearActionError: true,
      clearActionSuccess: true,
    ));

    final result = await _jobDataSource.updateJobFlag(
      jobId: event.jobId,
      isFlagged: event.isFlagged,
      flagNote: event.flagNote,
    );

    result.fold(
      (failure) {
        // Remove from in-flight and show error
        final newInFlight = Map<String, JobActionType>.from(currentState.inFlightActions);
        newInFlight.remove(event.jobId);
        emit(currentState.copyWith(
          inFlightActions: newInFlight,
          actionError: _getErrorMessage(failure, 'flag'),
        ));
      },
      (updatedJob) {
        // Update job in list
        final newJobs = _updateJobInList(currentState.jobs, updatedJob);
        final newFilteredJobs = _updateJobInList(currentState.filteredJobs, updatedJob);
        final newInFlight = Map<String, JobActionType>.from(currentState.inFlightActions);
        newInFlight.remove(event.jobId);

        emit(currentState.copyWith(
          jobs: newJobs,
          filteredJobs: newFilteredJobs,
          inFlightActions: newInFlight,
          actionSuccess: event.isFlagged ? 'Job flagged' : 'Job unflagged',
        ));
      },
    );
  }

  /// Pause a job.
  Future<void> _onPauseJob(
    PauseJobEvent event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    // Set in-flight state
    final updatedInFlight = Map<String, JobActionType>.from(currentState.inFlightActions);
    updatedInFlight[event.jobId] = JobActionType.pause;
    emit(currentState.copyWith(
      inFlightActions: updatedInFlight,
      clearActionError: true,
      clearActionSuccess: true,
    ));

    final result = await _jobDataSource.pauseJob(event.jobId);

    result.fold(
      (failure) {
        // Remove from in-flight and show error
        final newInFlight = Map<String, JobActionType>.from(currentState.inFlightActions);
        newInFlight.remove(event.jobId);
        emit(currentState.copyWith(
          inFlightActions: newInFlight,
          actionError: _getErrorMessage(failure, 'pause'),
        ));
      },
      (updatedJob) {
        // Update job in list
        final newJobs = _updateJobInList(currentState.jobs, updatedJob);
        final newFilteredJobs = _updateJobInList(currentState.filteredJobs, updatedJob);
        final newInFlight = Map<String, JobActionType>.from(currentState.inFlightActions);
        newInFlight.remove(event.jobId);

        emit(currentState.copyWith(
          jobs: newJobs,
          filteredJobs: newFilteredJobs,
          inFlightActions: newInFlight,
          actionSuccess: 'Pause requested',
        ));
      },
    );
  }

  /// Resume a paused job.
  Future<void> _onResumeJob(
    ResumeJobEvent event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    // Set in-flight state
    final updatedInFlight = Map<String, JobActionType>.from(currentState.inFlightActions);
    updatedInFlight[event.jobId] = JobActionType.resume;
    emit(currentState.copyWith(
      inFlightActions: updatedInFlight,
      clearActionError: true,
      clearActionSuccess: true,
    ));

    final result = await _jobDataSource.resumeJob(event.jobId);

    result.fold(
      (failure) {
        // Remove from in-flight and show error
        final newInFlight = Map<String, JobActionType>.from(currentState.inFlightActions);
        newInFlight.remove(event.jobId);
        emit(currentState.copyWith(
          inFlightActions: newInFlight,
          actionError: _getErrorMessage(failure, 'resume'),
        ));
      },
      (updatedJob) {
        // Update job in list
        final newJobs = _updateJobInList(currentState.jobs, updatedJob);
        final newFilteredJobs = _updateJobInList(currentState.filteredJobs, updatedJob);
        final newInFlight = Map<String, JobActionType>.from(currentState.inFlightActions);
        newInFlight.remove(event.jobId);

        emit(currentState.copyWith(
          jobs: newJobs,
          filteredJobs: newFilteredJobs,
          inFlightActions: newInFlight,
          actionSuccess: 'Job resumed',
        ));
      },
    );
  }

  /// Cancel a processing or queued job.
  Future<void> _onCancelJob(
    CancelJobEvent event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    // Set in-flight state
    final updatedInFlight = Map<String, JobActionType>.from(currentState.inFlightActions);
    updatedInFlight[event.jobId] = JobActionType.cancel;
    emit(currentState.copyWith(
      inFlightActions: updatedInFlight,
      clearActionError: true,
      clearActionSuccess: true,
    ));

    final result = await _jobDataSource.cancelJob(event.jobId);

    result.fold(
      (failure) {
        // Remove from in-flight and show error
        final newInFlight = Map<String, JobActionType>.from(currentState.inFlightActions);
        newInFlight.remove(event.jobId);
        emit(currentState.copyWith(
          inFlightActions: newInFlight,
          actionError: _getErrorMessage(failure, 'cancel'),
        ));
      },
      (updatedJob) {
        // Update job in list
        final newJobs = _updateJobInList(currentState.jobs, updatedJob);
        final newFilteredJobs = _updateJobInList(currentState.filteredJobs, updatedJob);
        final newInFlight = Map<String, JobActionType>.from(currentState.inFlightActions);
        newInFlight.remove(event.jobId);

        emit(currentState.copyWith(
          jobs: newJobs,
          filteredJobs: newFilteredJobs,
          inFlightActions: newInFlight,
          actionSuccess: 'Job cancelled',
        ));
      },
    );
  }

  /// Load videos from a specific collection.
  Future<void> _onLoadCollectionVideos(
    LoadCollectionVideosEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (_collectionDataSource == null) return;

    emit(const HomeLoading());

    final result = await _collectionDataSource!
        .getCollectionVideos(event.collectionId);

    result.fold(
      (failure) => emit(HomeError(failure)),
      (jobs) {
        emit(HomeLoaded(
          jobs: jobs,
          filteredJobs: jobs,
        ));
      },
    );
  }

  /// Toggle view mode between list and grid.
  void _onToggleViewMode(
    ToggleViewModeEvent event,
    Emitter<HomeState> emit,
  ) {
    final currentState = state;
    if (currentState is HomeLoaded) {
      final newMode = currentState.viewMode == ViewMode.list
          ? ViewMode.grid
          : ViewMode.list;
      emit(currentState.copyWith(viewMode: newMode));
    }
  }

  /// Update a job in the list by replacing it with the updated version.
  List<JobModel> _updateJobInList(List<JobModel> jobs, JobModel updatedJob) {
    return jobs.map((j) => j.jobId == updatedJob.jobId ? updatedJob : j).toList();
  }

  /// Get a user-friendly error message based on failure type and action.
  String _getErrorMessage(Failure failure, String action) {
    // Check for 409 Conflict status
    if (failure is HttpFailure && failure.statusCode == 409) {
      switch (action) {
        case 'delete':
          return 'Cannot delete while job is processing or flagged';
        case 'pause':
        case 'resume':
          return 'Cannot change state in the current job status';
        case 'flag':
          return 'Cannot flag this job right now';
        case 'cancel':
          return 'Cannot cancel a job in this status';
        default:
          return failure.message;
      }
    }
    return failure.message;
  }

  /// Filter jobs by search query only (status now filtered server-side).
  List<JobModel> _filterJobsBySearch(List<JobModel> jobs, String searchQuery) {
    if (searchQuery.isEmpty) return jobs;

    final query = searchQuery.toLowerCase();
    return jobs.where((job) {
      final title = job.title?.toLowerCase() ?? '';
      final description = job.description?.toLowerCase() ?? '';
      final url = job.sourceUrl?.toLowerCase() ?? '';
      final filename = job.filename?.toLowerCase() ?? '';

      return title.contains(query) ||
          description.contains(query) ||
          url.contains(query) ||
          filename.contains(query);
    }).toList();
  }

  /// Filter jobs by search query and status (legacy, for client-side filtering).
  List<JobModel> _filterJobs(
    List<JobModel> jobs,
    String searchQuery,
    String? statusFilter,
  ) {
    var filtered = jobs;

    // Apply status filter
    if (statusFilter != null && statusFilter.isNotEmpty) {
      filtered = filtered.where((job) {
        return job.status.toLowerCase() == statusFilter.toLowerCase();
      }).toList();
    }

    // Apply search query
    return _filterJobsBySearch(filtered, searchQuery);
  }
}
