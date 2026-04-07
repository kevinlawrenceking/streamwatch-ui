part of 'podcast_list_bloc.dart';

/// Events for the PodcastList BLoC.
abstract class PodcastListEvent extends Equatable {
  const PodcastListEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch podcasts with pagination.
class FetchPodcastsEvent extends PodcastListEvent {
  final int page;
  final int pageSize;
  final bool includeInactive;

  const FetchPodcastsEvent({
    this.page = 1,
    this.pageSize = 20,
    this.includeInactive = false,
  });

  @override
  List<Object?> get props => [page, pageSize, includeInactive];
}

/// Create a new podcast.
class CreatePodcastEvent extends PodcastListEvent {
  final Map<String, dynamic> body;

  const CreatePodcastEvent(this.body);

  @override
  List<Object?> get props => [body];
}

/// Deactivate a podcast.
class DeactivatePodcastEvent extends PodcastListEvent {
  final String podcastId;

  const DeactivatePodcastEvent(this.podcastId);

  @override
  List<Object?> get props => [podcastId];
}

/// Activate a deactivated podcast.
class ActivatePodcastEvent extends PodcastListEvent {
  final String podcastId;

  const ActivatePodcastEvent(this.podcastId);

  @override
  List<Object?> get props => [podcastId];
}
