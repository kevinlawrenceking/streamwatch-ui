import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/job_model.dart';
import '../../../data/sources/job_data_source.dart';
import '../../../shared/errors/failures/failure.dart';

part 'jobs_list_event.dart';
part 'jobs_list_state.dart';

/// BLoC for managing the jobs list feature.
class JobsListBloc extends Bloc<JobsListEvent, JobsListState> {
  final IJobDataSource _dataSource;

  JobsListBloc({required IJobDataSource dataSource})
      : _dataSource = dataSource,
        super(const JobsListInitial()) {
    on<LoadJobsEvent>(_onLoadJobs);
    on<RefreshJobsEvent>(_onRefreshJobs);
  }

  Future<void> _onLoadJobs(
    LoadJobsEvent event,
    Emitter<JobsListState> emit,
  ) async {
    emit(const JobsListLoading());

    final result = await _dataSource.getRecentJobs(limit: event.limit);

    if (isClosed) return;

    result.fold(
      (failure) => emit(JobsListError(failure)),
      (jobs) => emit(JobsListLoaded(jobs)),
    );
  }

  Future<void> _onRefreshJobs(
    RefreshJobsEvent event,
    Emitter<JobsListState> emit,
  ) async {
    // Keep current data visible while refreshing (for pull-to-refresh UX)
    final currentState = state;
    if (currentState is JobsListLoaded) {
      emit(JobsListRefreshing(currentState.jobs));
    }

    final result = await _dataSource.getRecentJobs(limit: event.limit);

    if (isClosed) return;

    result.fold(
      (failure) => emit(JobsListError(failure)),
      (jobs) => emit(JobsListLoaded(jobs)),
    );
  }
}
