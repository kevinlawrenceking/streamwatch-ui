part of 'reports_dashboard_bloc.dart';

abstract class ReportsDashboardEvent extends Equatable {
  const ReportsDashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadReportsDashboard extends ReportsDashboardEvent {
  const LoadReportsDashboard();
}

class RefreshReportsDashboard extends ReportsDashboardEvent {
  const RefreshReportsDashboard();
}
