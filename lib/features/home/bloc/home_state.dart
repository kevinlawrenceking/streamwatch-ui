import 'package:equatable/equatable.dart';
import '../../../data/models/job_model.dart';
import '../../../shared/errors/failures/failure.dart';

/// Types of job actions that can be in-flight.
enum JobActionType { delete, flag, pause, resume }

/// View mode for the jobs list.
enum ViewMode { list, grid }

/// States for the home BLoC.
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded.
class HomeInitial extends HomeState {
  const HomeInitial();
}

/// Loading state while fetching jobs.
class HomeLoading extends HomeState {
  const HomeLoading();
}

/// Jobs loaded successfully.
class HomeLoaded extends HomeState {
  final List<JobModel> jobs;
  final List<JobModel> filteredJobs;
  final String searchQuery;
  final String? statusFilter;

  /// Map of jobId -> action type currently in-flight for that job.
  /// Empty map means no actions are in-flight.
  final Map<String, JobActionType> inFlightActions;

  /// Error message to show in snackbar (cleared after display).
  final String? actionError;

  /// Success message to show in snackbar (cleared after display).
  final String? actionSuccess;

  /// Current view mode (list or grid).
  final ViewMode viewMode;

  const HomeLoaded({
    required this.jobs,
    required this.filteredJobs,
    this.searchQuery = '',
    this.statusFilter,
    this.inFlightActions = const {},
    this.actionError,
    this.actionSuccess,
    this.viewMode = ViewMode.list,
  });

  @override
  List<Object?> get props => [
        jobs,
        filteredJobs,
        searchQuery,
        statusFilter,
        inFlightActions,
        actionError,
        actionSuccess,
        viewMode,
      ];

  /// Check if a job has any action in-flight.
  bool isJobActionInFlight(String jobId) => inFlightActions.containsKey(jobId);

  /// Get the action type in-flight for a job, if any.
  JobActionType? getInFlightAction(String jobId) => inFlightActions[jobId];

  HomeLoaded copyWith({
    List<JobModel>? jobs,
    List<JobModel>? filteredJobs,
    String? searchQuery,
    String? statusFilter,
    Map<String, JobActionType>? inFlightActions,
    String? actionError,
    String? actionSuccess,
    bool clearActionError = false,
    bool clearActionSuccess = false,
    ViewMode? viewMode,
  }) {
    return HomeLoaded(
      jobs: jobs ?? this.jobs,
      filteredJobs: filteredJobs ?? this.filteredJobs,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter,
      inFlightActions: inFlightActions ?? this.inFlightActions,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      actionSuccess:
          clearActionSuccess ? null : (actionSuccess ?? this.actionSuccess),
      viewMode: viewMode ?? this.viewMode,
    );
  }
}

/// Refreshing state (keeps current data visible).
class HomeRefreshing extends HomeState {
  final List<JobModel> jobs;
  final List<JobModel> filteredJobs;
  final String searchQuery;
  final String? statusFilter;
  final ViewMode viewMode;

  const HomeRefreshing({
    required this.jobs,
    required this.filteredJobs,
    this.searchQuery = '',
    this.statusFilter,
    this.viewMode = ViewMode.list,
  });

  @override
  List<Object?> get props => [jobs, filteredJobs, searchQuery, statusFilter, viewMode];
}

/// Error state.
class HomeError extends HomeState {
  final Failure failure;

  const HomeError(this.failure);

  @override
  List<Object?> get props => [failure];
}
