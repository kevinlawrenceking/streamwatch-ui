import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/data_sources/podcast_data_source.dart';
import '../../data/models/podcast_episode.dart';

part 'episode_list_event.dart';
part 'episode_list_state.dart';

/// BLoC for the episode list view.
class EpisodeListBloc extends Bloc<EpisodeListEvent, EpisodeListState> {
  final IPodcastDataSource _dataSource;

  EpisodeListBloc({required IPodcastDataSource dataSource})
      : _dataSource = dataSource,
        super(const EpisodeListInitial()) {
    on<FetchEpisodesEvent>(_onFetchEpisodes);
  }

  Future<void> _onFetchEpisodes(
    FetchEpisodesEvent event,
    Emitter<EpisodeListState> emit,
  ) async {
    final currentState = state;
    final isLoadMore = event.page > 1 && currentState is EpisodeListLoaded;

    if (!isLoadMore) {
      emit(const EpisodeListLoading());
    }

    final result = await _dataSource.listEpisodes(
      event.podcastId,
      page: event.page,
      pageSize: event.pageSize,
    );

    result.fold(
      (failure) => emit(EpisodeListError(failure.message)),
      (response) {
        final allEpisodes = isLoadMore
            ? [
                ...(currentState as EpisodeListLoaded).episodes,
                ...response.items
              ]
            : response.items;
        emit(EpisodeListLoaded(
          episodes: allEpisodes,
          hasMore: response.hasMore,
          currentPage: event.page,
        ));
      },
    );
  }
}
