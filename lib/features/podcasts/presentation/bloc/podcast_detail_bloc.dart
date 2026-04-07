import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/data_sources/podcast_data_source.dart';
import '../../data/models/podcast.dart';
import '../../data/models/podcast_platform.dart';
import '../../data/models/podcast_schedule.dart';

part 'podcast_detail_event.dart';
part 'podcast_detail_state.dart';

/// BLoC for the podcast detail view.
class PodcastDetailBloc extends Bloc<PodcastDetailEvent, PodcastDetailState> {
  final IPodcastDataSource _dataSource;

  PodcastDetailBloc({required IPodcastDataSource dataSource})
      : _dataSource = dataSource,
        super(const PodcastDetailInitial()) {
    on<FetchPodcastDetailEvent>(_onFetchDetail);
    on<UpdatePodcastEvent>(_onUpdatePodcast);
    on<AddPlatformEvent>(_onAddPlatform);
    on<UpdatePlatformEvent>(_onUpdatePlatform);
    on<DeletePlatformEvent>(_onDeletePlatform);
    on<AddScheduleEvent>(_onAddSchedule);
    on<UpdateScheduleEvent>(_onUpdateSchedule);
    on<DeleteScheduleEvent>(_onDeleteSchedule);
  }

  Future<void> _onFetchDetail(
    FetchPodcastDetailEvent event,
    Emitter<PodcastDetailState> emit,
  ) async {
    emit(const PodcastDetailLoading());

    final podcastResult = await _dataSource.getPodcast(event.podcastId);

    await podcastResult.fold(
      (failure) async => emit(PodcastDetailError(failure.message)),
      (podcast) async {
        final platformsResult =
            await _dataSource.listPlatforms(event.podcastId);
        final schedulesResult =
            await _dataSource.listSchedules(event.podcastId);

        final platforms = platformsResult.fold(
          (_) => <PodcastPlatformModel>[],
          (list) => list,
        );
        final schedules = schedulesResult.fold(
          (_) => <PodcastScheduleModel>[],
          (list) => list,
        );

        emit(PodcastDetailLoaded(
          podcast: podcast,
          platforms: platforms,
          schedules: schedules,
        ));
      },
    );
  }

  Future<void> _onUpdatePodcast(
    UpdatePodcastEvent event,
    Emitter<PodcastDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PodcastDetailLoaded) return;

    final result =
        await _dataSource.updatePodcast(event.podcastId, event.body);

    result.fold(
      (failure) =>
          emit(currentState.copyWith(actionError: failure.message)),
      (updatedPodcast) =>
          emit(currentState.copyWith(podcast: updatedPodcast)),
    );
  }

  Future<void> _onAddPlatform(
    AddPlatformEvent event,
    Emitter<PodcastDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PodcastDetailLoaded) return;

    final result =
        await _dataSource.createPlatform(event.podcastId, event.body);

    result.fold(
      (failure) =>
          emit(currentState.copyWith(actionError: failure.message)),
      (platform) {
        emit(currentState.copyWith(
          platforms: [...currentState.platforms, platform],
        ));
      },
    );
  }

  Future<void> _onUpdatePlatform(
    UpdatePlatformEvent event,
    Emitter<PodcastDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PodcastDetailLoaded) return;

    final result =
        await _dataSource.updatePlatform(event.platformId, event.body);

    result.fold(
      (failure) =>
          emit(currentState.copyWith(actionError: failure.message)),
      (updated) {
        final updatedList = currentState.platforms
            .map((p) => p.id == updated.id ? updated : p)
            .toList();
        emit(currentState.copyWith(platforms: updatedList));
      },
    );
  }

  Future<void> _onDeletePlatform(
    DeletePlatformEvent event,
    Emitter<PodcastDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PodcastDetailLoaded) return;

    final result = await _dataSource.deletePlatform(event.platformId);

    result.fold(
      (failure) =>
          emit(currentState.copyWith(actionError: failure.message)),
      (_) {
        final filtered = currentState.platforms
            .where((p) => p.id != event.platformId)
            .toList();
        emit(currentState.copyWith(platforms: filtered));
      },
    );
  }

  Future<void> _onAddSchedule(
    AddScheduleEvent event,
    Emitter<PodcastDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PodcastDetailLoaded) return;

    final result =
        await _dataSource.createSchedule(event.podcastId, event.body);

    result.fold(
      (failure) =>
          emit(currentState.copyWith(actionError: failure.message)),
      (schedule) {
        emit(currentState.copyWith(
          schedules: [...currentState.schedules, schedule],
        ));
      },
    );
  }

  Future<void> _onUpdateSchedule(
    UpdateScheduleEvent event,
    Emitter<PodcastDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PodcastDetailLoaded) return;

    final result =
        await _dataSource.updateSchedule(event.scheduleId, event.body);

    result.fold(
      (failure) =>
          emit(currentState.copyWith(actionError: failure.message)),
      (updated) {
        final updatedList = currentState.schedules
            .map((s) => s.id == updated.id ? updated : s)
            .toList();
        emit(currentState.copyWith(schedules: updatedList));
      },
    );
  }

  Future<void> _onDeleteSchedule(
    DeleteScheduleEvent event,
    Emitter<PodcastDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PodcastDetailLoaded) return;

    final result = await _dataSource.deleteSchedule(event.scheduleId);

    result.fold(
      (failure) =>
          emit(currentState.copyWith(actionError: failure.message)),
      (_) {
        final filtered = currentState.schedules
            .where((s) => s.id != event.scheduleId)
            .toList();
        emit(currentState.copyWith(schedules: filtered));
      },
    );
  }
}
