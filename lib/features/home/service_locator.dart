import 'package:get_it/get_it.dart';
import '../../data/sources/job_data_source.dart';
import 'bloc/home_bloc.dart';

/// Service locator for the home feature.
class ServiceLocator {
  static bool _initialized = false;

  /// Initializes feature dependencies.
  /// Must be called after global service locator is initialized.
  static void init() {
    if (_initialized) {
      throw Exception('Home ServiceLocator already initialized!');
    }

    final sl = GetIt.instance;

    // HomeBloc - factory (new instance each time)
    sl.registerFactory<HomeBloc>(
      () => HomeBloc(jobDataSource: sl<IJobDataSource>()),
    );

    _initialized = true;
  }
}
