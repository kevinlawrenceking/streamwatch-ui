import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/job_model.dart';
import '../../../data/sources/job_data_source.dart';

part 'scheduler_dashboard_event.dart';
part 'scheduler_dashboard_state.dart';

/// BLoC for the scheduler dashboard view.
/// Loads recent podcast-originated jobs (source=url, sourceProvider=youtube).
class SchedulerDashboardBloc
    extends Bloc<SchedulerDashboardEvent, SchedulerDashboardState> {
  final IJobDataSource _jobDataSource;

  SchedulerDashboardBloc({required IJobDataSource jobDataSource})
      : _jobDataSource = jobDataSource,
        super(const SchedulerDashboardInitial()) {
    on<LoadSchedulerDashboard>(_onLoad);
    on<RefreshSchedulerDashboard>(_onRefresh);
  }

  Future<void> _onLoad(
    LoadSchedulerDashboard event,
    Emitter<SchedulerDashboardState> emit,
  ) async {
    emit(const SchedulerDashboardLoading());
    await _fetchJobs(emit);
  }

  Future<void> _onRefresh(
    RefreshSchedulerDashboard event,
    Emitter<SchedulerDashboardState> emit,
  ) async {
    await _fetchJobs(emit);
  }

  Future<void> _fetchJobs(Emitter<SchedulerDashboardState> emit) async {
    final result = await _jobDataSource.getRecentJobs(
      limit: 50,
      source: 'url',
    );
    result.fold(
      (failure) => emit(SchedulerDashboardError(failure.toString())),
      (jobs) {
        // Separate into status buckets
        final queued = jobs.where((j) => j.status == 'queued').toList();
        final processing = jobs
            .where(
                (j) => j.status == 'processing' || j.status == 'transcribing')
            .toList();
        final completed = jobs.where((j) => j.status == 'completed').toList();
        final failed = jobs
            .where((j) => j.status == 'failed' || j.status == 'error')
            .toList();

        emit(SchedulerDashboardLoaded(
          recentJobs: jobs,
          queuedJobs: queued,
          processingJobs: processing,
          completedJobs: completed,
          failedJobs: failed,
        ));
      },
    );
  }
}
