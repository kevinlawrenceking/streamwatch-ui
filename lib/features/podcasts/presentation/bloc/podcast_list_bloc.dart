import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/data_sources/podcast_data_source.dart';
import '../../data/models/podcast.dart';

part 'podcast_list_event.dart';
part 'podcast_list_state.dart';

/// BLoC for the podcast list view.
class PodcastListBloc extends Bloc<PodcastListEvent, PodcastListState> {
  final IPodcastDataSource _dataSource;

  PodcastListBloc({required IPodcastDataSource dataSource})
      : _dataSource = dataSource,
        super(const PodcastListInitial()) {
    on<FetchPodcastsEvent>(_onFetchPodcasts);
    on<CreatePodcastEvent>(_onCreatePodcast);
    on<DeactivatePodcastEvent>(_onDeactivatePodcast);
    on<ActivatePodcastEvent>(_onActivatePodcast);
  }

  Future<void> _onFetchPodcasts(
    FetchPodcastsEvent event,
    Emitter<PodcastListState> emit,
  ) async {
    final currentState = state;
    final isLoadMore = event.page > 1 && currentState is PodcastListLoaded;

    if (!isLoadMore) {
      emit(const PodcastListLoading());
    }

    final result = await _dataSource.listPodcasts(
      page: event.page,
      pageSize: event.pageSize,
      includeInactive: event.includeInactive,
    );

    result.fold(
      (failure) => emit(PodcastListError(failure.message)),
      (response) {
        final allPodcasts = isLoadMore
            ? [
                ...currentState.podcasts,
                ...response.items
              ]
            : response.items;
        emit(PodcastListLoaded(
          podcasts: allPodcasts,
          hasMore: response.hasMore,
          includeInactive: event.includeInactive,
          currentPage: event.page,
        ));
      },
    );
  }

  Future<void> _onCreatePodcast(
    CreatePodcastEvent event,
    Emitter<PodcastListState> emit,
  ) async {
    final result = await _dataSource.createPodcast(event.body);

    result.fold(
      (failure) {
        final currentState = state;
        if (currentState is PodcastListLoaded) {
          emit(currentState.copyWith(actionError: failure.message));
        } else {
          emit(PodcastListError(failure.message));
        }
      },
      (_) {
        add(FetchPodcastsEvent(
          includeInactive: state is PodcastListLoaded
              ? (state as PodcastListLoaded).includeInactive
              : false,
        ));
      },
    );
  }

  Future<void> _onDeactivatePodcast(
    DeactivatePodcastEvent event,
    Emitter<PodcastListState> emit,
  ) async {
    final result = await _dataSource.deactivatePodcast(event.podcastId);

    result.fold(
      (failure) {
        final currentState = state;
        if (currentState is PodcastListLoaded) {
          emit(currentState.copyWith(actionError: failure.message));
        }
      },
      (_) {
        add(FetchPodcastsEvent(
          includeInactive: state is PodcastListLoaded
              ? (state as PodcastListLoaded).includeInactive
              : false,
        ));
      },
    );
  }

  Future<void> _onActivatePodcast(
    ActivatePodcastEvent event,
    Emitter<PodcastListState> emit,
  ) async {
    final result = await _dataSource.activatePodcast(event.podcastId);

    result.fold(
      (failure) {
        final currentState = state;
        if (currentState is PodcastListLoaded) {
          emit(currentState.copyWith(actionError: failure.message));
        }
      },
      (_) {
        add(FetchPodcastsEvent(
          includeInactive: state is PodcastListLoaded
              ? (state as PodcastListLoaded).includeInactive
              : false,
        ));
      },
    );
  }
}
