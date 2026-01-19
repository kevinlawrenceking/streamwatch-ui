part of 'job_detail_bloc.dart';

/// Base class for job detail events.
abstract class JobDetailEvent extends Equatable {
  const JobDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load initial job details.
class LoadJobDetailEvent extends JobDetailEvent {
  const LoadJobDetailEvent();
}

/// Event to refresh job details from API.
class RefreshJobDetailEvent extends JobDetailEvent {
  const RefreshJobDetailEvent();
}

/// Event to start polling for real-time updates.
///
/// Polling is used instead of WebSocket because WebSocket is not
/// supported in Lambda/API Gateway serverless deployments.
class StartPollingEvent extends JobDetailEvent {
  const StartPollingEvent();
}

/// Event to stop polling for updates.
class StopPollingEvent extends JobDetailEvent {
  const StopPollingEvent();
}

/// Internal event triggered by the poll timer.
/// Not intended for external use.
class _PollTickEvent extends JobDetailEvent {
  const _PollTickEvent();
}

/// Delete the current job.
class DeleteJobDetailEvent extends JobDetailEvent {
  const DeleteJobDetailEvent();
}

/// Toggle flag status of the current job.
class ToggleFlagJobDetailEvent extends JobDetailEvent {
  final bool isFlagged;
  final String? flagNote;

  const ToggleFlagJobDetailEvent({
    required this.isFlagged,
    this.flagNote,
  });

  @override
  List<Object?> get props => [isFlagged, flagNote];
}

/// Pause the current job.
class PauseJobDetailEvent extends JobDetailEvent {
  const PauseJobDetailEvent();
}

/// Resume the current job.
class ResumeJobDetailEvent extends JobDetailEvent {
  const ResumeJobDetailEvent();
}
