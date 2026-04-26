import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../podcasts/data/data_sources/podcast_data_source.dart';
import '../../../podcasts/data/models/podcast_transcript.dart';

part 'episode_transcripts_event.dart';
part 'episode_transcripts_state.dart';

/// Tab-scoped bloc for the Transcripts tab. Optimistic + rollback uniform
/// contract per WO-077 Plan §2.6.
class EpisodeTranscriptsBloc
    extends Bloc<EpisodeTranscriptsEvent, EpisodeTranscriptsState> {
  final IPodcastDataSource _dataSource;

  EpisodeTranscriptsBloc({required IPodcastDataSource dataSource})
      : _dataSource = dataSource,
        super(const EpisodeTranscriptsInitial()) {
    on<LoadTranscriptsEvent>(_onLoad);
    on<CreateTranscriptEvent>(_onCreate);
    on<PatchTranscriptEvent>(_onPatch);
    on<DeleteTranscriptEvent>(_onDelete);
    on<SetPrimaryTranscriptEvent>(_onSetPrimary);
    on<EpisodeTranscriptsErrorAcknowledged>(_onErrorAcknowledged);
  }

  Future<void> _onLoad(
    LoadTranscriptsEvent event,
    Emitter<EpisodeTranscriptsState> emit,
  ) async {
    emit(const EpisodeTranscriptsLoading());
    final result = await _dataSource.listTranscripts(event.episodeId);
    result.fold(
      (failure) => emit(EpisodeTranscriptsError(failure.message)),
      (list) => emit(EpisodeTranscriptsLoaded(transcripts: list)),
    );
  }

  Future<void> _onCreate(
    CreateTranscriptEvent event,
    Emitter<EpisodeTranscriptsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EpisodeTranscriptsLoaded) return;
    if (currentState.isMutating) return;

    final priorList = currentState.transcripts;
    emit(currentState.copyWith(
      isMutating: true,
      clearLastActionError: true,
    ));

    final result =
        await _dataSource.createTranscript(event.episodeId, event.body);
    final afterState = state;
    if (afterState is! EpisodeTranscriptsLoaded) return;

    result.fold(
      (failure) => emit(afterState.copyWith(
        transcripts: priorList,
        isMutating: false,
        lastActionError: failure.message,
      )),
      (created) => emit(afterState.copyWith(
        transcripts: [...priorList, created],
        isMutating: false,
        clearLastActionError: true,
      )),
    );
  }

  Future<void> _onPatch(
    PatchTranscriptEvent event,
    Emitter<EpisodeTranscriptsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EpisodeTranscriptsLoaded) return;
    if (currentState.isMutating) return;

    final priorList = currentState.transcripts;
    emit(currentState.copyWith(
      isMutating: true,
      clearLastActionError: true,
    ));

    final result =
        await _dataSource.patchTranscript(event.transcriptId, event.body);
    final afterState = state;
    if (afterState is! EpisodeTranscriptsLoaded) return;

    result.fold(
      (failure) => emit(afterState.copyWith(
        transcripts: priorList,
        isMutating: false,
        lastActionError: failure.message,
      )),
      (updated) => emit(afterState.copyWith(
        transcripts: afterState.transcripts
            .map((t) => t.id == updated.id ? updated : t)
            .toList(),
        isMutating: false,
        clearLastActionError: true,
      )),
    );
  }

  Future<void> _onDelete(
    DeleteTranscriptEvent event,
    Emitter<EpisodeTranscriptsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EpisodeTranscriptsLoaded) return;
    if (currentState.isMutating) return;

    final priorList = currentState.transcripts;
    final optimistic =
        priorList.where((t) => t.id != event.transcriptId).toList();

    emit(currentState.copyWith(
      transcripts: optimistic,
      isMutating: true,
      clearLastActionError: true,
    ));

    final result = await _dataSource.deleteTranscript(event.transcriptId);
    final afterState = state;
    if (afterState is! EpisodeTranscriptsLoaded) return;

    result.fold(
      (failure) => emit(afterState.copyWith(
        transcripts: priorList,
        isMutating: false,
        lastActionError: failure.message,
      )),
      (_) => emit(afterState.copyWith(
        isMutating: false,
        clearLastActionError: true,
      )),
    );
  }

  Future<void> _onSetPrimary(
    SetPrimaryTranscriptEvent event,
    Emitter<EpisodeTranscriptsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EpisodeTranscriptsLoaded) return;
    if (currentState.isMutating) return;

    final priorList = currentState.transcripts;
    final optimistic = priorList
        .map((t) => t.copyWith(isPrimary: t.id == event.transcriptId))
        .toList();

    emit(currentState.copyWith(
      transcripts: optimistic,
      isMutating: true,
      clearLastActionError: true,
    ));

    final result = await _dataSource.setPrimaryTranscript(event.transcriptId);
    final afterState = state;
    if (afterState is! EpisodeTranscriptsLoaded) return;

    result.fold(
      (failure) => emit(afterState.copyWith(
        transcripts: priorList,
        isMutating: false,
        lastActionError: failure.message,
      )),
      (updated) => emit(afterState.copyWith(
        transcripts: afterState.transcripts
            .map((t) =>
                t.id == updated.id ? updated : t.copyWith(isPrimary: false))
            .toList(),
        isMutating: false,
        clearLastActionError: true,
      )),
    );
  }

  void _onErrorAcknowledged(
    EpisodeTranscriptsErrorAcknowledged event,
    Emitter<EpisodeTranscriptsState> emit,
  ) {
    final currentState = state;
    if (currentState is! EpisodeTranscriptsLoaded) return;
    if (currentState.lastActionError == null) return;
    emit(currentState.copyWith(clearLastActionError: true));
  }
}
