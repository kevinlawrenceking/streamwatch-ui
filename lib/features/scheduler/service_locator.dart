import 'package:get_it/get_it.dart';

import '../../data/sources/job_data_source.dart';
import 'bloc/scheduler_dashboard_bloc.dart';

/// Service locator for Scheduler feature.
class ServiceLocator {
  static bool _initialized = false;

  static void init() {
    if (_initialized) {
      throw Exception('Scheduler ServiceLocator already initialized!');
    }
    final sl = GetIt.instance;

    sl.registerFactory<SchedulerDashboardBloc>(
      () => SchedulerDashboardBloc(jobDataSource: sl<IJobDataSource>()),
    );

    _initialized = true;
  }
}
