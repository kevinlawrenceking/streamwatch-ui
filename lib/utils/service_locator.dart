import 'package:get_it/get_it.dart';
import '../data/providers/rest_client.dart';
import '../data/sources/auth_data_source.dart';
import '../data/sources/collection_data_source.dart';
import '../data/sources/job_data_source.dart';
import '../data/sources/user_data_source.dart';
import '../shared/bloc/auth_session_bloc.dart';
import 'config.dart';

// Feature service locators
import '../features/home/service_locator.dart' as home;
import '../features/jobs_list/service_locator.dart' as jobs_list;
import '../features/upload/service_locator.dart' as upload;
import '../features/job_detail/service_locator.dart' as job_detail;
import '../features/login/service_locator.dart' as login;
import '../features/collections/service_locator.dart' as collections;
import '../features/users/service_locator.dart' as users;

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

  // Auth Data Source - gated by AUTH_REQUIRED flag with API guardrail.
  // When authRequired=true, probe GET /api/v1/jobs to verify the API
  // has auth middleware enabled. If the probe returns 401, auth is live.
  // If 200 (no middleware), 500 (tables missing), or timeout, fall back
  // to DevAuthDataSource to prevent the dead-login state.
  bool useAuth = config.authRequired && !config.isDevelopment;
  if (useAuth) {
    try {
      final response = await sl<IRestClient>()
          .get(endPoint: '/api/v1/jobs', queryParams: {'limit': '1'})
          .timeout(const Duration(seconds: 5));
      useAuth = response.statusCode == 401;
    } catch (_) {
      useAuth = false;
    }
  }

  if (useAuth) {
    sl.registerSingleton<IAuthDataSource>(
      ProdAuthDataSource(
        client: sl<IRestClient>(),
        authSessionBloc: sl<AuthSessionBloc>(),
      ),
    );
  } else {
    sl.registerSingleton<IAuthDataSource>(DevAuthDataSource());
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

  // User Data Source - depends on auth and client
  if (useAuth) {
    sl.registerSingleton<IUserDataSource>(
      ProdUserDataSource(
        auth: sl<IAuthDataSource>(),
        client: sl<IRestClient>(),
      ),
    );
  } else {
    sl.registerSingleton<IUserDataSource>(DevUserDataSource());
  }

  // Collection Data Source - depends on auth and client
  sl.registerSingleton<ICollectionDataSource>(
    CollectionDataSource(
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
  users.ServiceLocator.init();
  collections.ServiceLocator.init();
}

/// Resets the service locator (useful for testing).
Future<void> resetServiceLocator() async {
  await sl.reset();
}
