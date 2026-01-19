import 'dart:async';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../../data/models/job_model.dart';
import '../../../data/models/chunk_model.dart';
import '../../../data/models/celebrity_model.dart';
import '../../../data/sources/job_data_source.dart';
import '../../../shared/errors/failures/failure.dart';

part 'job_detail_event.dart';
part 'job_detail_state.dart';

/// BLoC for managing job detail view with HTTP polling for real-time updates.
///
/// WebSocket is not supported in Lambda/API Gateway serverless deployments,
/// so this BLoC uses HTTP polling instead:
/// - Polls every 1-2 seconds while job is processing
/// - Uses exponential backoff on errors (2s, 4s, 8s... up to 30s)
/// - Stops polling when job reaches terminal state (completed/failed/cancelled)
class JobDetailBloc extends Bloc<JobDetailEvent, JobDetailState> {
  final IJobDataSource _dataSource;
  final String jobId;

  /// Timer for periodic polling
  Timer? _pollTimer;

  /// Current polling interval (adjusts with backoff)
  Duration _pollInterval = const Duration(seconds: 2);

  /// Base polling interval when job is active
  static const Duration _basePollInterval = Duration(seconds: 2);

  /// Maximum backoff interval on repeated errors
  static const Duration _maxBackoffInterval = Duration(seconds: 30);

  /// Number of consecutive poll errors (for backoff calculation)
  int _consecutiveErrors = 0;

  /// Maximum consecutive errors before showing error state in UI
  static const int _maxErrorsBeforeWarning = 5;

  JobDetailBloc({
    required IJobDataSource dataSource,
    required this.jobId,
  })  : _dataSource = dataSource,
        super(const JobDetailInitial()) {
    on<LoadJobDetailEvent>(_onLoadJobDetail);
    on<RefreshJobDetailEvent>(_onRefreshJobDetail);
    on<StartPollingEvent>(_onStartPolling);
    on<StopPollingEvent>(_onStopPolling);
    on<_PollTickEvent>(_onPollTick);
    on<DeleteJobDetailEvent>(_onDeleteJob);
    on<ToggleFlagJobDetailEvent>(_onToggleFlagJob);
    on<PauseJobDetailEvent>(_onPauseJob);
    on<ResumeJobDetailEvent>(_onResumeJob);
  }

  Future<void> _onLoadJobDetail(
    LoadJobDetailEvent event,
    Emitter<JobDetailState> emit,
  ) async {
    emit(const JobDetailLoading());

    final jobResult = await _dataSource.getJobWithCelebrities(jobId);
    final chunksResult = await _dataSource.getJobChunks(jobId);

    if (isClosed) return;

    jobResult.fold(
      (failure) => emit(JobDetailError(failure)),
      (result) {
        final chunks = chunksResult.fold(
          (failure) => <ChunkModel>[],
          (chunks) => chunks,
        );
        emit(JobDetailLoaded(
          job: result.job,
          chunks: chunks,
          celebrities: result.celebrities,
          isPolling: false,
          pollError: null,
        ));

        // Auto-start polling after successful load if job is not in terminal state
        if (!_isTerminalState(result.job.status)) {
          add(const StartPollingEvent());
        }
      },
    );
  }

  Future<void> _onRefreshJobDetail(
    RefreshJobDetailEvent event,
    Emitter<JobDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! JobDetailLoaded) return;

    final jobResult = await _dataSource.getJobWithCelebrities(jobId);
    final chunksResult = await _dataSource.getJobChunks(jobId);

    if (isClosed) return;

    jobResult.fold(
      (failure) {
        // On refresh error, increment error count for backoff
        _consecutiveErrors++;
        _pollInterval = _calculateBackoff();
        debugPrint('Poll error #$_consecutiveErrors, next interval: ${_pollInterval.inSeconds}s');

        // Show warning if too many consecutive errors
        if (_consecutiveErrors >= _maxErrorsBeforeWarning) {
          emit(currentState.copyWith(
            pollError: 'Connection issues - retrying every ${_pollInterval.inSeconds}s',
          ));
        }
      },
      (result) {
        // Reset error count on success
        _consecutiveErrors = 0;
        _pollInterval = _basePollInterval;

        final chunks = chunksResult.fold(
          (failure) => currentState.chunks,
          (chunks) => chunks,
        );

        emit(currentState.copyWith(
          job: result.job,
          chunks: chunks,
          celebrities: result.celebrities,
          pollError: null, // Clear any previous error
        ));

        // Stop polling if job reached terminal state
        if (_isTerminalState(result.job.status)) {
          debugPrint('Job reached terminal state: ${result.job.status}, stopping polling');
          add(const StopPollingEvent());
        }
      },
    );
  }

  void _onStartPolling(
    StartPollingEvent event,
    Emitter<JobDetailState> emit,
  ) {
    final currentState = state;
    if (currentState is! JobDetailLoaded) return;

    // Don't start polling if job is already in terminal state
    if (_isTerminalState(currentState.job.status)) {
      debugPrint('Job already in terminal state, not starting polling');
      return;
    }

    // Cancel any existing timer
    _pollTimer?.cancel();

    // Reset polling state
    _consecutiveErrors = 0;
    _pollInterval = _basePollInterval;

    debugPrint('Starting polling for job $jobId every ${_pollInterval.inSeconds}s');

    emit(currentState.copyWith(isPolling: true, pollError: null));

    // Start periodic polling
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!isClosed) {
        add(const _PollTickEvent());
      }
    });
  }

  void _onStopPolling(
    StopPollingEvent event,
    Emitter<JobDetailState> emit,
  ) {
    debugPrint('Stopping polling for job $jobId');
    _pollTimer?.cancel();
    _pollTimer = null;

    final currentState = state;
    if (currentState is JobDetailLoaded) {
      emit(currentState.copyWith(isPolling: false));
    }
  }

  Future<void> _onPollTick(
    _PollTickEvent event,
    Emitter<JobDetailState> emit,
  ) async {
    // Refresh job data
    add(const RefreshJobDetailEvent());

    // If we had errors and interval changed, recreate timer with new interval
    if (_consecutiveErrors > 0 && _pollTimer != null) {
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(_pollInterval, (_) {
        if (!isClosed) {
          add(const _PollTickEvent());
        }
      });
    }
  }

  /// Calculate backoff interval using exponential backoff with jitter
  Duration _calculateBackoff() {
    // Exponential backoff: 2^errors * base interval, capped at max
    final backoffSeconds = min(
      _maxBackoffInterval.inSeconds,
      _basePollInterval.inSeconds * pow(2, _consecutiveErrors).toInt(),
    );

    // Add small random jitter (0-500ms) to prevent thundering herd
    final jitterMs = Random().nextInt(500);

    return Duration(seconds: backoffSeconds, milliseconds: jitterMs);
  }

  /// Check if job status is terminal (no more updates expected)
  bool _isTerminalState(String status) {
    return status == 'completed' || status == 'failed' || status == 'cancelled';
  }

  /// Delete the job.
  Future<void> _onDeleteJob(
    DeleteJobDetailEvent event,
    Emitter<JobDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! JobDetailLoaded) return;

    emit(currentState.copyWith(
      inFlightAction: JobDetailActionType.delete,
      clearActionError: true,
      clearActionSuccess: true,
    ));

    final result = await _dataSource.deleteJob(jobId);

    result.fold(
      (failure) {
        emit(currentState.copyWith(
          clearInFlightAction: true,
          actionError: _getErrorMessage(failure, 'delete'),
        ));
      },
      (_) {
        emit(currentState.copyWith(
          clearInFlightAction: true,
          actionSuccess: 'Job deleted',
          jobDeleted: true,
        ));
      },
    );
  }

  /// Toggle flag status.
  Future<void> _onToggleFlagJob(
    ToggleFlagJobDetailEvent event,
    Emitter<JobDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! JobDetailLoaded) return;

    emit(currentState.copyWith(
      inFlightAction: JobDetailActionType.flag,
      clearActionError: true,
      clearActionSuccess: true,
    ));

    final result = await _dataSource.updateJobFlag(
      jobId: jobId,
      isFlagged: event.isFlagged,
      flagNote: event.flagNote,
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(
          clearInFlightAction: true,
          actionError: _getErrorMessage(failure, 'flag'),
        ));
      },
      (updatedJob) {
        emit(currentState.copyWith(
          job: updatedJob,
          clearInFlightAction: true,
          actionSuccess: event.isFlagged ? 'Job flagged' : 'Job unflagged',
        ));
      },
    );
  }

  /// Pause the job.
  Future<void> _onPauseJob(
    PauseJobDetailEvent event,
    Emitter<JobDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! JobDetailLoaded) return;

    emit(currentState.copyWith(
      inFlightAction: JobDetailActionType.pause,
      clearActionError: true,
      clearActionSuccess: true,
    ));

    final result = await _dataSource.pauseJob(jobId);

    result.fold(
      (failure) {
        emit(currentState.copyWith(
          clearInFlightAction: true,
          actionError: _getErrorMessage(failure, 'pause'),
        ));
      },
      (updatedJob) {
        emit(currentState.copyWith(
          job: updatedJob,
          clearInFlightAction: true,
          actionSuccess: 'Pause requested',
        ));
      },
    );
  }

  /// Resume the job.
  Future<void> _onResumeJob(
    ResumeJobDetailEvent event,
    Emitter<JobDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! JobDetailLoaded) return;

    emit(currentState.copyWith(
      inFlightAction: JobDetailActionType.resume,
      clearActionError: true,
      clearActionSuccess: true,
    ));

    final result = await _dataSource.resumeJob(jobId);

    result.fold(
      (failure) {
        emit(currentState.copyWith(
          clearInFlightAction: true,
          actionError: _getErrorMessage(failure, 'resume'),
        ));
      },
      (updatedJob) {
        emit(currentState.copyWith(
          job: updatedJob,
          clearInFlightAction: true,
          actionSuccess: 'Job resumed',
        ));
      },
    );
  }

  /// Get a user-friendly error message based on failure type and action.
  String _getErrorMessage(Failure failure, String action) {
    if (failure is HttpFailure && failure.statusCode == 409) {
      switch (action) {
        case 'delete':
          return 'Cannot delete while job is processing or flagged';
        case 'pause':
        case 'resume':
          return 'Cannot change state in the current job status';
        case 'flag':
          return 'Cannot flag this job right now';
        default:
          return failure.message;
      }
    }
    return failure.message;
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
