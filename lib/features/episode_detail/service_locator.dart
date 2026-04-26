import 'package:get_it/get_it.dart';

import '../podcasts/data/data_sources/podcast_data_source.dart';
import 'presentation/bloc/episode_detail_bloc.dart';
import 'presentation/bloc/episode_headlines_bloc.dart';
import 'presentation/bloc/episode_notifications_bloc.dart';
import 'presentation/bloc/episode_transcripts_bloc.dart';

/// Service locator for the Episode Detail feature (WO-077 / LSW-015).
/// Registers 4 BLoCs as factories. The shared IPodcastDataSource is owned
/// by the podcasts feature ServiceLocator -- this init() must run AFTER
/// podcasts.ServiceLocator.init().
class ServiceLocator {
  static bool _initialized = false;

  static void init() {
    if (_initialized) {
      throw Exception('Episode Detail ServiceLocator already initialized!');
    }
    final sl = GetIt.instance;

    sl.registerFactory<EpisodeDetailBloc>(
      () => EpisodeDetailBloc(dataSource: sl<IPodcastDataSource>()),
    );

    sl.registerFactory<EpisodeTranscriptsBloc>(
      () => EpisodeTranscriptsBloc(dataSource: sl<IPodcastDataSource>()),
    );

    sl.registerFactory<EpisodeHeadlinesBloc>(
      () => EpisodeHeadlinesBloc(dataSource: sl<IPodcastDataSource>()),
    );

    sl.registerFactory<EpisodeNotificationsBloc>(
      () => EpisodeNotificationsBloc(dataSource: sl<IPodcastDataSource>()),
    );

    _initialized = true;
  }
}
