import 'package:get_it/get_it.dart';

import '../../data/providers/rest_client.dart';
import '../../data/sources/auth_data_source.dart';
import 'data/data_sources/detection_data_source.dart';
import 'data/data_sources/jobs_data_source.dart';
import 'presentation/bloc/detection_bloc.dart';
import 'presentation/bloc/jobs_bloc.dart';

/// Service locator for the Jobs feature (LSW-016 / WO-078). Registers
/// both data sources as lazy singletons (stateless), and the JobsBloc
/// + DetectionBloc as factories (view-scoped). Must run AFTER core
/// Auth + RestClient registration in lib/utils/service_locator.dart.
///
/// Distinct from the legacy `lib/features/jobs_list/` feature (upload
/// pipeline jobs surface) -- this Jobs feature is for podcast-jobs +
/// detection-runs.
class ServiceLocator {
  static bool _initialized = false;

  static void init() {
    if (_initialized) {
      throw Exception('Jobs ServiceLocator already initialized!');
    }
    final sl = GetIt.instance;

    sl.registerLazySingleton<IJobsDataSource>(
      () => JobsDataSource(
        auth: sl<IAuthDataSource>(),
        client: sl<IRestClient>(),
      ),
    );

    sl.registerLazySingleton<IDetectionDataSource>(
      () => DetectionDataSource(
        auth: sl<IAuthDataSource>(),
        client: sl<IRestClient>(),
      ),
    );

    sl.registerFactory<JobsBloc>(
      () => JobsBloc(dataSource: sl<IJobsDataSource>()),
    );

    sl.registerFactory<DetectionBloc>(
      () => DetectionBloc(dataSource: sl<IDetectionDataSource>()),
    );

    _initialized = true;
  }
}
