import 'package:get_it/get_it.dart';

import '../../data/providers/rest_client.dart';
import '../../data/sources/auth_data_source.dart';
import 'data/data_sources/podcast_data_source.dart';
import 'presentation/bloc/episode_list_bloc.dart';
import 'presentation/bloc/podcast_detail_bloc.dart';
import 'presentation/bloc/podcast_list_bloc.dart';

/// Service locator for the podcasts feature.
class ServiceLocator {
  static bool _initialized = false;

  /// Initializes feature dependencies.
  /// Must be called after global service locator is initialized.
  static void init() {
    if (_initialized) {
      throw Exception('Podcasts ServiceLocator already initialized!');
    }

    final sl = GetIt.instance;

    // Data Source
    sl.registerLazySingleton<IPodcastDataSource>(
      () => PodcastDataSource(
        auth: sl<IAuthDataSource>(),
        client: sl<IRestClient>(),
      ),
    );

    // BLoCs
    sl.registerFactory<PodcastListBloc>(
      () => PodcastListBloc(dataSource: sl<IPodcastDataSource>()),
    );

    sl.registerFactory<PodcastDetailBloc>(
      () => PodcastDetailBloc(dataSource: sl<IPodcastDataSource>()),
    );

    sl.registerFactory<EpisodeListBloc>(
      () => EpisodeListBloc(dataSource: sl<IPodcastDataSource>()),
    );

    _initialized = true;
  }
}
