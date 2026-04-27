import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/errors/failures/failure.dart';
import '../../data/data_sources/jobs_data_source.dart';
import '../../data/models/podcast_job.dart';

part 'jobs_event.dart';
part 'jobs_state.dart';

/// Operations bloc for the Jobs tab.
///
/// Single mutation path: retry. Captures `priorState` and on success
/// (HTTP 202) flips the row status to `'queued'` plus surfaces toast
/// L-1 (`Retry queued for ${jobId}`) via `lastActionMessage`. On 404
/// (toast L-2) restores priorState with `Job not found`.
///
/// No optimistic list-add anywhere; retry mutates an existing row only.
class JobsBloc extends Bloc<JobsEvent, JobsState> {
  final IJobsDataSource _dataSource;

  JobsBloc({required IJobsDataSource dataSource})
      : _dataSource = dataSource,
        super(const JobsInitial()) {
    on<LoadJobsEvent>(_onLoad);
    on<JobsFilterChangedEvent>(_onFilterChanged);
    on<RetryJobEvent>(_onRetry);
    on<JobsErrorAcknowledged>(_onErrorAcknowledged);
  }

  Future<void> _onLoad(
    LoadJobsEvent event,
    Emitter<JobsState> emit,
  ) async {
    emit(const JobsLoading());
    final result = await _dataSource.listPodcastJobs(
      status: event.status,
      podcastId: event.podcastId,
      createdFrom: event.createdFrom,
      createdTo: event.createdTo,
    );
    result.fold(
      (failure) => emit(JobsError(failure.message)),
      (list) => emit(JobsLoaded(
        jobs: list,
        statusFilter: event.status,
        podcastFilter: event.podcastId,
        createdFrom: event.createdFrom,
        createdTo: event.createdTo,
      )),
    );
  }

  Future<void> _onFilterChanged(
    JobsFilterChangedEvent event,
    Emitter<JobsState> emit,
  ) async {
    final current = state;
    if (current is! JobsLoaded) return;
    emit(current.copyWith(isMutating: true, clearLastActionError: true));
    final result = await _dataSource.listPodcastJobs(
      status: event.status,
      podcastId: event.podcastId,
      createdFrom: event.createdFrom,
      createdTo: event.createdTo,
    );
    result.fold(
      (failure) => emit(current.copyWith(
        isMutating: false,
        lastActionError: failure.message,
      )),
      (list) => emit(JobsLoaded(
        jobs: list,
        statusFilter: event.status,
        podcastFilter: event.podcastId,
        createdFrom: event.createdFrom,
        createdTo: event.createdTo,
      )),
    );
  }

  Future<void> _onRetry(
    RetryJobEvent event,
    Emitter<JobsState> emit,
  ) async {
    final current = state;
    if (current is! JobsLoaded) return;
    if (current.isMutating) return;

    final priorState = current;
    emit(current.copyWith(isMutating: true, clearLastActionError: true));

    final result = await _dataSource.retryPodcastJob(event.jobId);
    final after = state;
    if (after is! JobsLoaded) return;

    result.fold(
      (failure) {
        if (failure is HttpFailure && failure.statusCode == 404) {
          // Toast L-2: Job not found. Restore prior; row unchanged.
          emit(priorState.copyWith(
            isMutating: false,
            lastActionError: 'Job not found',
          ));
        } else {
          emit(priorState.copyWith(
            isMutating: false,
            lastActionError: failure.message,
          ));
        }
      },
      (_) {
        // Toast L-1: 202 Accepted. Single emit -- flip row status to
        // queued, clear retry-related error fields, surface success
        // toast via lastActionMessage. No re-fetch (RFC 7231 async --
        // user refreshes for the next state).
        final updatedJobs = after.jobs
            .map((j) => j.jobId == event.jobId
                ? j.copyWith(
                    status: 'queued',
                    errorCode: null,
                    errorMessage: null,
                  )
                : j)
            .toList();
        emit(after.copyWith(
          jobs: updatedJobs,
          isMutating: false,
          clearLastActionError: true,
          lastActionMessage: 'Retry queued for ${event.jobId}',
        ));
      },
    );
  }

  void _onErrorAcknowledged(
    JobsErrorAcknowledged event,
    Emitter<JobsState> emit,
  ) {
    final current = state;
    if (current is! JobsLoaded) return;
    if (current.lastActionError == null && current.lastActionMessage == null) {
      return;
    }
    emit(current.copyWith(
      clearLastActionError: true,
      clearLastActionMessage: true,
    ));
  }
}
