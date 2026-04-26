import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/errors/failures/failure.dart';
import '../../../podcasts/data/data_sources/podcast_data_source.dart';
import '../../../podcasts/data/models/podcast_episode.dart';

part 'episode_detail_event.dart';
part 'episode_detail_state.dart';

/// View-scoped bloc owning the single PodcastEpisodeModel rendered by
/// EpisodeDetailView and the action-bar mutations (Mark Reviewed,
/// Request Clip, Edit Metadata).
///
/// Tabs (transcripts / headlines / notifications) subscribe to this bloc
/// via BlocListener and refetch when [PodcastEpisodeModel] equality changes
/// (Lock #3).
class EpisodeDetailBloc extends Bloc<EpisodeDetailEvent, EpisodeDetailState> {
  final IPodcastDataSource _dataSource;

  EpisodeDetailBloc({required IPodcastDataSource dataSource})
      : _dataSource = dataSource,
        super(const EpisodeDetailInitial()) {
    on<LoadEpisodeEvent>(_onLoad);
    on<RefreshEpisodeEvent>(_onRefresh);
    on<MarkReviewedEvent>(_onMarkReviewed);
    on<RequestClipEvent>(_onRequestClip);
    on<EditMetadataEvent>(_onEditMetadata);
    on<EpisodeDetailErrorAcknowledged>(_onErrorAcknowledged);
  }

  Future<void> _onLoad(
    LoadEpisodeEvent event,
    Emitter<EpisodeDetailState> emit,
  ) async {
    emit(const EpisodeDetailLoading());
    final result = await _dataSource.getEpisode(event.episodeId);
    result.fold(
      (failure) => emit(EpisodeDetailError(failure.message)),
      (episode) => emit(EpisodeDetailLoaded(episode: episode)),
    );
  }

  Future<void> _onRefresh(
    RefreshEpisodeEvent event,
    Emitter<EpisodeDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EpisodeDetailLoaded) return;

    final result = await _dataSource.getEpisode(currentState.episode.id);
    result.fold(
      (failure) => emit(currentState.copyWith(
        lastActionError: failure.message,
      )),
      (episode) => emit(currentState.copyWith(
        episode: episode,
        isMutating: false,
        clearLastActionError: true,
      )),
    );
  }

  Future<void> _onMarkReviewed(
    MarkReviewedEvent event,
    Emitter<EpisodeDetailState> emit,
  ) =>
      _handleAction(
        emit,
        action: () => _dataSource.markEpisodeReviewed(event.episodeId),
      );

  Future<void> _onRequestClip(
    RequestClipEvent event,
    Emitter<EpisodeDetailState> emit,
  ) =>
      _handleAction(
        emit,
        action: () => _dataSource.requestEpisodeClip(event.episodeId),
      );

  Future<void> _onEditMetadata(
    EditMetadataEvent event,
    Emitter<EpisodeDetailState> emit,
  ) =>
      _handleAction(
        emit,
        action: () => _dataSource.updateEpisode(event.episodeId, event.body),
      );

  Future<void> _handleAction(
    Emitter<EpisodeDetailState> emit, {
    required Future<Either<Failure, PodcastEpisodeModel>> Function() action,
  }) async {
    final currentState = state;
    if (currentState is! EpisodeDetailLoaded) return;
    if (currentState.isMutating) return;

    emit(currentState.copyWith(
      isMutating: true,
      clearLastActionError: true,
    ));

    final result = await action();

    final afterState = state;
    if (afterState is! EpisodeDetailLoaded) return;

    result.fold(
      (failure) => emit(afterState.copyWith(
        isMutating: false,
        lastActionError: failure.message,
      )),
      (updatedEpisode) => emit(afterState.copyWith(
        episode: updatedEpisode,
        isMutating: false,
        clearLastActionError: true,
      )),
    );
  }

  void _onErrorAcknowledged(
    EpisodeDetailErrorAcknowledged event,
    Emitter<EpisodeDetailState> emit,
  ) {
    final currentState = state;
    if (currentState is! EpisodeDetailLoaded) return;
    if (currentState.lastActionError == null) return;
    emit(currentState.copyWith(clearLastActionError: true));
  }
}
