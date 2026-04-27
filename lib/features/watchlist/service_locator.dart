import 'package:get_it/get_it.dart';

import '../../data/providers/rest_client.dart';
import '../../data/sources/auth_data_source.dart';
import 'data/data_sources/guest_watchlist_data_source.dart';
import 'presentation/bloc/watchlist_bloc.dart';

/// Service locator for the Watchlist feature (LSW-016 / WO-078).
/// Registers IGuestWatchlistDataSource as a lazy singleton (HTTP client
/// is stateless) and WatchlistBloc as a factory (view-scoped, disposed
/// on route pop). This init() must run AFTER the core Auth + RestClient
/// singletons are registered in lib/utils/service_locator.dart.
class ServiceLocator {
  static bool _initialized = false;

  static void init() {
    if (_initialized) {
      throw Exception('Watchlist ServiceLocator already initialized!');
    }
    final sl = GetIt.instance;

    sl.registerLazySingleton<IGuestWatchlistDataSource>(
      () => GuestWatchlistDataSource(
        auth: sl<IAuthDataSource>(),
        client: sl<IRestClient>(),
      ),
    );

    sl.registerFactory<WatchlistBloc>(
      () => WatchlistBloc(dataSource: sl<IGuestWatchlistDataSource>()),
    );

    _initialized = true;
  }
}
