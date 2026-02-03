import 'package:get_it/get_it.dart';
import '../../data/sources/job_data_source.dart';
import 'bloc/jobs_list_bloc.dart';

/// Service locator for the jobs_list feature.
class ServiceLocator {
  static bool _initialized = false;

  /// Initializes feature dependencies.
  /// Must be called after global service locator is initialized.
  static void init() {
    if (_initialized) {
      throw Exception('JobsList ServiceLocator already initialized!');
    }

    final sl = GetIt.instance;

    // BLoCs as factories - new instance per widget
    sl.registerFactory<JobsListBloc>(
      () => JobsListBloc(dataSource: sl<IJobDataSource>()),
    );

    _initialized = true;
  }
}
