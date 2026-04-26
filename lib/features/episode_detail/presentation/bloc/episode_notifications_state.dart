part of 'episode_notifications_bloc.dart';

abstract class EpisodeNotificationsState extends Equatable {
  const EpisodeNotificationsState();
  @override
  List<Object?> get props => [];
}

class EpisodeNotificationsInitial extends EpisodeNotificationsState {
  const EpisodeNotificationsInitial();
}

class EpisodeNotificationsLoading extends EpisodeNotificationsState {
  const EpisodeNotificationsLoading();
}

class EpisodeNotificationsLoaded extends EpisodeNotificationsState {
  final List<PodcastNotificationModel> notifications;
  final bool isMutating;
  final String? lastActionError;

  const EpisodeNotificationsLoaded({
    required this.notifications,
    this.isMutating = false,
    this.lastActionError,
  });

  EpisodeNotificationsLoaded copyWith({
    List<PodcastNotificationModel>? notifications,
    bool? isMutating,
    String? lastActionError,
    bool clearLastActionError = false,
  }) {
    return EpisodeNotificationsLoaded(
      notifications: notifications ?? this.notifications,
      isMutating: isMutating ?? this.isMutating,
      lastActionError: clearLastActionError
          ? null
          : (lastActionError ?? this.lastActionError),
    );
  }

  @override
  List<Object?> get props => [notifications, isMutating, lastActionError];
}

class EpisodeNotificationsError extends EpisodeNotificationsState {
  final String message;
  const EpisodeNotificationsError(this.message);
  @override
  List<Object?> get props => [message];
}
