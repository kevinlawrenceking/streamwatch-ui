part of 'scheduler_dashboard_bloc.dart';

abstract class SchedulerDashboardState extends Equatable {
  const SchedulerDashboardState();

  @override
  List<Object?> get props => [];
}

class SchedulerDashboardInitial extends SchedulerDashboardState {
  const SchedulerDashboardInitial();
}

class SchedulerDashboardLoading extends SchedulerDashboardState {
  const SchedulerDashboardLoading();
}

class SchedulerDashboardLoaded extends SchedulerDashboardState {
  final List<JobModel> recentJobs;
  final List<JobModel> queuedJobs;
  final List<JobModel> processingJobs;
  final List<JobModel> completedJobs;
  final List<JobModel> failedJobs;

  const SchedulerDashboardLoaded({
    required this.recentJobs,
    required this.queuedJobs,
    required this.processingJobs,
    required this.completedJobs,
    required this.failedJobs,
  });

  @override
  List<Object?> get props => [
        recentJobs,
        queuedJobs,
        processingJobs,
        completedJobs,
        failedJobs,
      ];
}

class SchedulerDashboardError extends SchedulerDashboardState {
  final String message;

  const SchedulerDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
