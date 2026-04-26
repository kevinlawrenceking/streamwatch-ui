part of 'episode_detail_bloc.dart';

/// Events for the EpisodeDetail BLoC.
abstract class EpisodeDetailEvent extends Equatable {
  const EpisodeDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load of the episode by id.
class LoadEpisodeEvent extends EpisodeDetailEvent {
  final String episodeId;
  const LoadEpisodeEvent(this.episodeId);
  @override
  List<Object?> get props => [episodeId];
}

/// Re-fetch the current episode (e.g. pull-to-refresh on the view).
class RefreshEpisodeEvent extends EpisodeDetailEvent {
  const RefreshEpisodeEvent();
}

/// Action-bar: mark the current episode as reviewed.
class MarkReviewedEvent extends EpisodeDetailEvent {
  final String episodeId;
  const MarkReviewedEvent(this.episodeId);
  @override
  List<Object?> get props => [episodeId];
}

/// Action-bar: request a clip for the current episode.
class RequestClipEvent extends EpisodeDetailEvent {
  final String episodeId;
  const RequestClipEvent(this.episodeId);
  @override
  List<Object?> get props => [episodeId];
}

/// Action-bar: PATCH metadata fields. Body is built by EditMetadataDialog.
class EditMetadataEvent extends EpisodeDetailEvent {
  final String episodeId;
  final Map<String, dynamic> body;
  const EditMetadataEvent({required this.episodeId, required this.body});
  @override
  List<Object?> get props => [episodeId, body];
}

/// Clear the lastActionError after the SnackBar surfaces it.
class EpisodeDetailErrorAcknowledged extends EpisodeDetailEvent {
  const EpisodeDetailErrorAcknowledged();
}
