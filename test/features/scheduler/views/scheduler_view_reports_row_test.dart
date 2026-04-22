import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:streamwatch_frontend/features/scheduler/bloc/scheduler_dashboard_bloc.dart';
import 'package:streamwatch_frontend/features/scheduler/reports/bloc/reports_dashboard_bloc.dart';
import 'package:streamwatch_frontend/features/scheduler/reports/constants/report_keys.dart';
import 'package:streamwatch_frontend/features/scheduler/reports/widgets/report_count_card.dart';
import 'package:streamwatch_frontend/features/scheduler/views/scheduler_view.dart';
import 'package:streamwatch_frontend/features/scheduler/widgets/summary_card.dart';
import 'package:streamwatch_frontend/themes/app_theme.dart';

class FakeSchedulerDashboardBloc
    extends Bloc<SchedulerDashboardEvent, SchedulerDashboardState>
    implements SchedulerDashboardBloc {
  FakeSchedulerDashboardBloc(super.seed) {
    on<LoadSchedulerDashboard>((e, emit) {});
    on<RefreshSchedulerDashboard>((e, emit) {});
  }
}

class FakeReportsDashboardBloc
    extends Bloc<ReportsDashboardEvent, ReportsDashboardState>
    implements ReportsDashboardBloc {
  FakeReportsDashboardBloc(super.seed) {
    on<LoadReportsDashboard>((e, emit) {});
    on<RefreshReportsDashboard>((e, emit) {});
  }
}

Widget _host({
  required SchedulerDashboardState scheduler,
  required ReportsDashboardState reports,
}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<SchedulerDashboardBloc>(
            create: (_) => FakeSchedulerDashboardBloc(scheduler),
          ),
          BlocProvider<ReportsDashboardBloc>(
            create: (_) => FakeReportsDashboardBloc(reports),
          ),
        ],
        child: const SchedulerView(),
      ),
    ),
  );
}

void main() {
  // The horizontally-scrolled reports row lazy-instantiates via
  // ListView.builder; the default 800x600 test surface clips ~2 of the 7
  // cards off-screen. Each test sets a wider surface so all 7 are built.
  testWidgets('renders reports row even when scheduler bloc is Loading (E8)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host(
      scheduler: const SchedulerDashboardLoading(),
      reports: const ReportsDashboardLoaded(counts: {'late': 3}, errors: {}),
    ));
    // All 7 ReportCountCards render
    expect(find.byType(ReportCountCard), findsNWidgets(kReports.length));
    // Scheduler-specific area shows loading (not full-screen takeover)
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets(
      'renders reports row even when scheduler bloc errored (E8)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host(
      scheduler: const SchedulerDashboardError('jobs endpoint down'),
      reports: const ReportsDashboardLoaded(counts: {}, errors: {}),
    ));
    expect(find.byType(ReportCountCard), findsNWidgets(kReports.length));
    expect(find.text('jobs endpoint down'), findsOneWidget);
  });

  testWidgets(
      'renders summary row + jobs sections alongside reports row when Loaded',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host(
      scheduler: const SchedulerDashboardLoaded(
        recentJobs: [],
        queuedJobs: [],
        processingJobs: [],
        completedJobs: [],
        failedJobs: [],
      ),
      reports: const ReportsDashboardLoaded(counts: {}, errors: {}),
    ));
    expect(find.byType(SchedulerSummaryCard), findsNWidgets(4));
    expect(find.byType(ReportCountCard), findsNWidgets(kReports.length));
  });

  testWidgets('Loading reports render loading state on count cards',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host(
      scheduler: const SchedulerDashboardLoaded(
        recentJobs: [],
        queuedJobs: [],
        processingJobs: [],
        completedJobs: [],
        failedJobs: [],
      ),
      reports: const ReportsDashboardLoading(),
    ));
    // 7 cards still render; each showing a small progress indicator
    expect(find.byType(ReportCountCard), findsNWidgets(kReports.length));
  });
}
