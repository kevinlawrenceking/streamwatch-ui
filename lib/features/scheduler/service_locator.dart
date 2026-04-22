import 'package:get_it/get_it.dart';

import '../../data/providers/rest_client.dart';
import '../../data/sources/auth_data_source.dart';
import '../../data/sources/job_data_source.dart';
import 'bloc/scheduler_dashboard_bloc.dart';
import 'reports/bloc/reported_episodes_bloc.dart';
import 'reports/bloc/reported_slots_bloc.dart';
import 'reports/bloc/reports_dashboard_bloc.dart';
import 'reports/data/data_sources/reports_data_source.dart';

/// Service locator for Scheduler feature (dashboard + reports).
class ServiceLocator {
  static bool _initialized = false;

  static void init() {
    if (_initialized) {
      throw Exception('Scheduler ServiceLocator already initialized!');
    }
    final sl = GetIt.instance;

    // --- Dashboard (LSW-010) -------------------------------------------------
    sl.registerFactory<SchedulerDashboardBloc>(
      () => SchedulerDashboardBloc(jobDataSource: sl<IJobDataSource>()),
    );

    // --- Reports (WO-076 / LSW-014) -----------------------------------------
    sl.registerLazySingleton<IReportsDataSource>(
      () => ReportsDataSource(
        auth: sl<IAuthDataSource>(),
        client: sl<IRestClient>(),
      ),
    );

    // ReportsDashboardBloc is a lazy singleton so the same instance is
    // shared between /scheduler and /scheduler/reports routes. Drill-down
    // blocs dispatch RefreshReportsDashboard on action success to decrement
    // the count cards.
    sl.registerLazySingleton<ReportsDashboardBloc>(
      () => ReportsDashboardBloc(dataSource: sl<IReportsDataSource>()),
    );

    // Drill-down blocs: factory (new instance per route) with the dashboard
    // bloc constructor-injected (D4 — no GetIt inside bloc body).
    sl.registerFactory<ReportedSlotsBloc>(
      () => ReportedSlotsBloc(dataSource: sl<IReportsDataSource>()),
    );
    sl.registerFactory<ReportedEpisodesBloc>(
      () => ReportedEpisodesBloc(
        dataSource: sl<IReportsDataSource>(),
        dashboardBloc: sl<ReportsDashboardBloc>(),
      ),
    );

    _initialized = true;
  }
}
