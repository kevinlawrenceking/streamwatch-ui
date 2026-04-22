part of 'reports_dashboard_bloc.dart';

abstract class ReportsDashboardState extends Equatable {
  const ReportsDashboardState();

  @override
  List<Object?> get props => [];
}

class ReportsDashboardInitial extends ReportsDashboardState {
  const ReportsDashboardInitial();
}

class ReportsDashboardLoading extends ReportsDashboardState {
  const ReportsDashboardLoading();
}

class ReportsDashboardLoaded extends ReportsDashboardState {
  /// Slug -> total count for slugs whose fetch succeeded.
  final Map<String, int> counts;

  /// Slug -> error message for slugs whose fetch failed. An empty map means
  /// all 7 slugs loaded. Non-empty indicates partial degradation; the
  /// ReportCountCard renders an error badge for affected slugs.
  final Map<String, String> errors;

  const ReportsDashboardLoaded({
    required this.counts,
    required this.errors,
  });

  @override
  List<Object?> get props => [counts, errors];
}
