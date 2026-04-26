import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/errors/failures/failure.dart';
import '../../../podcasts/data/data_sources/podcast_data_source.dart';
import '../../../podcasts/data/models/podcast_notification.dart';

part 'episode_notifications_event.dart';
part 'episode_notifications_state.dart';

/// Tab-scoped bloc for the Notifications tab. Optimistic + rollback uniform
/// contract per WO-077 Plan §2.6. Send carries a 503 path (provider not
/// configured -- toast "Notification provider not configured -- contact
/// infra" per Pre-Approved Lock #7).
class EpisodeNotificationsBloc
    extends Bloc<EpisodeNotificationsEvent, EpisodeNotificationsState> {
  final IPodcastDataSource _dataSource;

  EpisodeNotificationsBloc({required IPodcastDataSource dataSource})
      : _dataSource = dataSource,
        super(const EpisodeNotificationsInitial()) {
    on<LoadNotificationsEvent>(_onLoad);
    on<CreateNotificationEvent>(_onCreate);
    on<DeleteNotificationEvent>(_onDelete);
    on<SendNotificationEvent>(_onSend);
    on<EpisodeNotificationsErrorAcknowledged>(_onErrorAcknowledged);
  }

  Future<void> _onLoad(
    LoadNotificationsEvent event,
    Emitter<EpisodeNotificationsState> emit,
  ) async {
    emit(const EpisodeNotificationsLoading());
    final result = await _dataSource.listNotifications(event.episodeId);
    result.fold(
      (failure) => emit(EpisodeNotificationsError(failure.message)),
      (list) => emit(EpisodeNotificationsLoaded(notifications: list)),
    );
  }

  Future<void> _onCreate(
    CreateNotificationEvent event,
    Emitter<EpisodeNotificationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EpisodeNotificationsLoaded) return;
    if (currentState.isMutating) return;

    final priorList = currentState.notifications;
    emit(currentState.copyWith(
      isMutating: true,
      clearLastActionError: true,
    ));

    final result =
        await _dataSource.createNotification(event.episodeId, event.body);
    final afterState = state;
    if (afterState is! EpisodeNotificationsLoaded) return;

    result.fold(
      (failure) => emit(afterState.copyWith(
        notifications: priorList,
        isMutating: false,
        lastActionError: failure.message,
      )),
      (created) => emit(afterState.copyWith(
        notifications: [...priorList, created],
        isMutating: false,
        clearLastActionError: true,
      )),
    );
  }

  Future<void> _onDelete(
    DeleteNotificationEvent event,
    Emitter<EpisodeNotificationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EpisodeNotificationsLoaded) return;
    if (currentState.isMutating) return;

    final priorList = currentState.notifications;
    final optimistic =
        priorList.where((n) => n.id != event.notificationId).toList();

    emit(currentState.copyWith(
      notifications: optimistic,
      isMutating: true,
      clearLastActionError: true,
    ));

    final result = await _dataSource.deleteNotification(event.notificationId);
    final afterState = state;
    if (afterState is! EpisodeNotificationsLoaded) return;

    result.fold(
      (failure) => emit(afterState.copyWith(
        notifications: priorList,
        isMutating: false,
        lastActionError: failure.message,
      )),
      (_) => emit(afterState.copyWith(
        isMutating: false,
        clearLastActionError: true,
      )),
    );
  }

  Future<void> _onSend(
    SendNotificationEvent event,
    Emitter<EpisodeNotificationsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EpisodeNotificationsLoaded) return;
    if (currentState.isMutating) return;

    final priorList = currentState.notifications;
    emit(currentState.copyWith(
      isMutating: true,
      clearLastActionError: true,
    ));

    final result = await _dataSource.sendNotification(event.notificationId);
    final afterState = state;
    if (afterState is! EpisodeNotificationsLoaded) return;

    result.fold(
      (failure) {
        // Pre-Approved Lock #7: 503 = provider unconfigured. Specific message.
        final message = (failure is HttpFailure && failure.statusCode == 503)
            ? 'Notification provider not configured -- contact infra'
            : failure.message;
        emit(afterState.copyWith(
          notifications: priorList,
          isMutating: false,
          lastActionError: message,
        ));
      },
      (updated) => emit(afterState.copyWith(
        notifications:
            priorList.map((n) => n.id == updated.id ? updated : n).toList(),
        isMutating: false,
        clearLastActionError: true,
      )),
    );
  }

  void _onErrorAcknowledged(
    EpisodeNotificationsErrorAcknowledged event,
    Emitter<EpisodeNotificationsState> emit,
  ) {
    final currentState = state;
    if (currentState is! EpisodeNotificationsLoaded) return;
    if (currentState.lastActionError == null) return;
    emit(currentState.copyWith(clearLastActionError: true));
  }
}
