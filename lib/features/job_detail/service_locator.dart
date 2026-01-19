import 'package:get_it/get_it.dart';
import '../../data/sources/job_data_source.dart';
import 'bloc/job_detail_bloc.dart';

/// Service locator for the job_detail feature.
class ServiceLocator {
  static bool _initialized = false;

  /// Initializes feature dependencies.
  /// Must be called after global service locator is initialized.
  static void init() {
    if (_initialized) {
      throw Exception('JobDetail ServiceLocator already initialized!');
    }

    final sl = GetIt.instance;

    // Note: JobDetailBloc requires a jobId parameter, so it's registered
    // as a factory that takes the jobId. The view will use factoryParam.
    sl.registerFactoryParam<JobDetailBloc, String, void>(
      (jobId, _) => JobDetailBloc(
        dataSource: sl<IJobDataSource>(),
        jobId: jobId,
      ),
    );

    _initialized = true;
  }
}
