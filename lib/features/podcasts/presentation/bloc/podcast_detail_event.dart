part of 'podcast_detail_bloc.dart';

/// Events for the PodcastDetail BLoC.
abstract class PodcastDetailEvent extends Equatable {
  const PodcastDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch podcast detail with platforms and schedules.
class FetchPodcastDetailEvent extends PodcastDetailEvent {
  final String podcastId;

  const FetchPodcastDetailEvent(this.podcastId);

  @override
  List<Object?> get props => [podcastId];
}

/// Update podcast name/description.
class UpdatePodcastEvent extends PodcastDetailEvent {
  final String podcastId;
  final Map<String, dynamic> body;

  const UpdatePodcastEvent({required this.podcastId, required this.body});

  @override
  List<Object?> get props => [podcastId, body];
}

/// Add a platform link to the podcast.
class AddPlatformEvent extends PodcastDetailEvent {
  final String podcastId;
  final Map<String, dynamic> body;

  const AddPlatformEvent({required this.podcastId, required this.body});

  @override
  List<Object?> get props => [podcastId, body];
}

/// Update an existing platform link.
class UpdatePlatformEvent extends PodcastDetailEvent {
  final String platformId;
  final Map<String, dynamic> body;

  const UpdatePlatformEvent({required this.platformId, required this.body});

  @override
  List<Object?> get props => [platformId, body];
}

/// Delete a platform link.
class DeletePlatformEvent extends PodcastDetailEvent {
  final String platformId;

  const DeletePlatformEvent(this.platformId);

  @override
  List<Object?> get props => [platformId];
}

/// Add a schedule slot to the podcast.
class AddScheduleEvent extends PodcastDetailEvent {
  final String podcastId;
  final Map<String, dynamic> body;

  const AddScheduleEvent({required this.podcastId, required this.body});

  @override
  List<Object?> get props => [podcastId, body];
}

/// Update an existing schedule slot.
class UpdateScheduleEvent extends PodcastDetailEvent {
  final String scheduleId;
  final Map<String, dynamic> body;

  const UpdateScheduleEvent({required this.scheduleId, required this.body});

  @override
  List<Object?> get props => [scheduleId, body];
}

/// Delete a schedule slot.
class DeleteScheduleEvent extends PodcastDetailEvent {
  final String scheduleId;

  const DeleteScheduleEvent(this.scheduleId);

  @override
  List<Object?> get props => [scheduleId];
}
