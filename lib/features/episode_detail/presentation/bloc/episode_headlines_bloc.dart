import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/errors/failures/failure.dart';
import '../../../podcasts/data/data_sources/podcast_data_source.dart';
import '../../../podcasts/data/models/podcast_headline_candidate.dart';

part 'episode_headlines_event.dart';
part 'episode_headlines_state.dart';

/// Tab-scoped bloc for the Headlines tab. Two distinct mutation paths:
///   1. Standard CRUD (create, delete, approve) -- optimistic + rollback.
///   2. Generate -- fire-and-forget (POST returns 202; UI flips
///      isGenerating=true, user must refresh to see new candidates per
///      Pre-Approved Lock #5).
///
/// Approve has a 409 race path (already finalized by another user); see
/// Pre-Approved Lock #8 -- specific message + auto-refetch.
class EpisodeHeadlinesBloc
    extends Bloc<EpisodeHeadlinesEvent, EpisodeHeadlinesState> {
  final IPodcastDataSource _dataSource;

  EpisodeHeadlinesBloc({required IPodcastDataSource dataSource})
      : _dataSource = dataSource,
        super(const EpisodeHeadlinesInitial()) {
    on<LoadHeadlinesEvent>(_onLoad);
    on<CreateHeadlineEvent>(_onCreate);
    on<DeleteHeadlineEvent>(_onDelete);
    on<ApproveHeadlineEvent>(_onApprove);
    on<GenerateHeadlinesEvent>(_onGenerate);
    on<EpisodeHeadlinesErrorAcknowledged>(_onErrorAcknowledged);
  }

  Future<void> _onLoad(
    LoadHeadlinesEvent event,
    Emitter<EpisodeHeadlinesState> emit,
  ) async {
    emit(const EpisodeHeadlinesLoading());
    final result = await _dataSource.listHeadlineCandidates(event.episodeId);
    result.fold(
      (failure) => emit(EpisodeHeadlinesError(failure.message)),
      (list) => emit(EpisodeHeadlinesLoaded(candidates: list)),
    );
  }

  Future<void> _onCreate(
    CreateHeadlineEvent event,
    Emitter<EpisodeHeadlinesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EpisodeHeadlinesLoaded) return;
    if (currentState.isMutating) return;

    final priorList = currentState.candidates;
    emit(currentState.copyWith(
      isMutating: true,
      clearLastActionError: true,
    ));

    final result =
        await _dataSource.createHeadlineCandidate(event.episodeId, event.body);
    final afterState = state;
    if (afterState is! EpisodeHeadlinesLoaded) return;

    result.fold(
      (failure) => emit(afterState.copyWith(
        candidates: priorList,
        isMutating: false,
        lastActionError: failure.message,
      )),
      (created) => emit(afterState.copyWith(
        candidates: [...priorList, created],
        isMutating: false,
        clearLastActionError: true,
      )),
    );
  }

  Future<void> _onDelete(
    DeleteHeadlineEvent event,
    Emitter<EpisodeHeadlinesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EpisodeHeadlinesLoaded) return;
    if (currentState.isMutating) return;

    final priorList = currentState.candidates;
    final optimistic =
        priorList.where((c) => c.id != event.candidateId).toList();

    emit(currentState.copyWith(
      candidates: optimistic,
      isMutating: true,
      clearLastActionError: true,
    ));

    final result = await _dataSource.deleteHeadlineCandidate(event.candidateId);
    final afterState = state;
    if (afterState is! EpisodeHeadlinesLoaded) return;

    result.fold(
      (failure) => emit(afterState.copyWith(
        candidates: priorList,
        isMutating: false,
        lastActionError: failure.message,
      )),
      (_) => emit(afterState.copyWith(
        isMutating: false,
        clearLastActionError: true,
      )),
    );
  }

  Future<void> _onApprove(
    ApproveHeadlineEvent event,
    Emitter<EpisodeHeadlinesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EpisodeHeadlinesLoaded) return;
    if (currentState.isMutating) return;

    final priorList = currentState.candidates;
    emit(currentState.copyWith(
      isMutating: true,
      clearLastActionError: true,
    ));

    final result =
        await _dataSource.approveHeadlineCandidate(event.candidateId);
    final afterState = state;
    if (afterState is! EpisodeHeadlinesLoaded) return;

    await result.fold(
      (failure) async {
        // Pre-Approved Lock #8: 409 = already finalized by another user.
        // Surface specific message + auto-refetch list.
        if (failure is HttpFailure && failure.statusCode == 409) {
          emit(afterState.copyWith(
            candidates: priorList,
            isMutating: false,
            lastActionError: 'Already finalized by another user',
          ));
          if (event.episodeId != null) {
            add(LoadHeadlinesEvent(event.episodeId!));
          }
        } else {
          emit(afterState.copyWith(
            candidates: priorList,
            isMutating: false,
            lastActionError: failure.message,
          ));
        }
      },
      (updated) async {
        emit(afterState.copyWith(
          candidates: afterState.candidates
              .map((c) => c.id == updated.id ? updated : c)
              .toList(),
          isMutating: false,
          clearLastActionError: true,
        ));
      },
    );
  }

  Future<void> _onGenerate(
    GenerateHeadlinesEvent event,
    Emitter<EpisodeHeadlinesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EpisodeHeadlinesLoaded) return;
    if (currentState.isMutating) return;
    if (currentState.isGenerating) return;

    emit(currentState.copyWith(
      isGenerating: true,
      clearLastActionError: true,
    ));

    final result = await _dataSource.generateHeadlines(event.episodeId);
    final afterState = state;
    if (afterState is! EpisodeHeadlinesLoaded) return;

    result.fold(
      (failure) => emit(afterState.copyWith(
        isGenerating: false,
        lastActionError: failure.message,
      )),
      // Lock #5: fire-and-forget. isGenerating stays true; user refreshes
      // to see new candidates. Tab does not poll. No second emit on success
      // -- the optimistic emit above already established the Generating
      // banner state.
      (_) {},
    );
  }

  void _onErrorAcknowledged(
    EpisodeHeadlinesErrorAcknowledged event,
    Emitter<EpisodeHeadlinesState> emit,
  ) {
    final currentState = state;
    if (currentState is! EpisodeHeadlinesLoaded) return;
    if (currentState.lastActionError == null) return;
    emit(currentState.copyWith(clearLastActionError: true));
  }
}
