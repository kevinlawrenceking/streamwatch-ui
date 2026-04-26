part of 'episode_notifications_bloc.dart';

abstract class EpisodeNotificationsEvent extends Equatable {
  const EpisodeNotificationsEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotificationsEvent extends EpisodeNotificationsEvent {
  final String episodeId;
  const LoadNotificationsEvent(this.episodeId);
  @override
  List<Object?> get props => [episodeId];
}

class CreateNotificationEvent extends EpisodeNotificationsEvent {
  final String episodeId;
  final Map<String, dynamic> body;
  const CreateNotificationEvent({
    required this.episodeId,
    required this.body,
  });
  @override
  List<Object?> get props => [episodeId, body];
}

class DeleteNotificationEvent extends EpisodeNotificationsEvent {
  final String notificationId;
  const DeleteNotificationEvent(this.notificationId);
  @override
  List<Object?> get props => [notificationId];
}

class SendNotificationEvent extends EpisodeNotificationsEvent {
  final String notificationId;
  const SendNotificationEvent(this.notificationId);
  @override
  List<Object?> get props => [notificationId];
}

class EpisodeNotificationsErrorAcknowledged extends EpisodeNotificationsEvent {
  const EpisodeNotificationsErrorAcknowledged();
}
