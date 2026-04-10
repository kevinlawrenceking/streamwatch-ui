part of 'scheduler_dashboard_bloc.dart';

abstract class SchedulerDashboardEvent extends Equatable {
  const SchedulerDashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadSchedulerDashboard extends SchedulerDashboardEvent {
  const LoadSchedulerDashboard();
}

class RefreshSchedulerDashboard extends SchedulerDashboardEvent {
  const RefreshSchedulerDashboard();
}
