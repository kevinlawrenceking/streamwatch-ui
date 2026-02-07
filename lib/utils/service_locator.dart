import 'package:get_it/get_it.dart';
import '../data/providers/rest_client.dart';
import '../data/sources/auth_data_source.dart';
import '../data/sources/job_data_source.dart';
import '../shared/bloc/auth_session_bloc.dart';
import 'config.dart';

// Feature service locators
import '../features/home/service_locator.dart' as home;
import '../features/jobs_list/service_locator.dart' as jobs_list;
import '../features/upload/service_locator.dart' as upload;
import '../features/job_detail/service_locator.dart' as job_detail;
import '../features/login/service_locator.dart' as login;

/// Global service locator instance.
final sl = GetIt.instance;

/// Initializes all dependencies in the service locator.
///
/// Must be called before runApp() in main.dart.
Future<void> initServiceLocator() async {
  final config = Config.instance;

  // ============================================================================
  // Core Services
  // ============================================================================

  // REST Client - singleton for all HTTP requests
  sl.registerSingleton<IRestClient>(
    RestClient(baseUrl: config.apiBaseUrl),
  );

  // ============================================================================
  // Auth Layer
  // ============================================================================

  // Auth Session BLoC - Global singleton for session state
  sl.registerSingleton(AuthSessionBloc());

  // Auth Data Source - Dev bypass or production implementation
  if (config.isDevelopment) {
    sl.registerSingleton<IAuthDataSource>(DevAuthDataSource());
  } else {
    sl.registerSingleton<IAuthDataSource>(
      ProdAuthDataSource(
        client: sl<IRestClient>(),
        authSessionBloc: sl<AuthSessionBloc>(),
      ),
    );
  }

  // ============================================================================
  // Data Sources
  // ============================================================================

  // Job Data Source - depends on auth and client
  sl.registerSingleton<IJobDataSource>(
    JobDataSource(
      auth: sl<IAuthDataSource>(),
      client: sl<IRestClient>(),
    ),
  );

  // ============================================================================
  // Feature Service Locators
  // ============================================================================

  login.ServiceLocator.init();
  home.ServiceLocator.init();
  jobs_list.ServiceLocator.init();
  upload.ServiceLocator.init();
  job_detail.ServiceLocator.init();
}

/// Resets the service locator (useful for testing).
Future<void> resetServiceLocator() async {
  await sl.reset();
}
