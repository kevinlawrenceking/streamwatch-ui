part of 'episode_list_bloc.dart';

/// Events for the EpisodeList BLoC.
abstract class EpisodeListEvent extends Equatable {
  const EpisodeListEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch episodes for a podcast with pagination.
class FetchEpisodesEvent extends EpisodeListEvent {
  final String podcastId;
  final int page;
  final int pageSize;

  const FetchEpisodesEvent({
    required this.podcastId,
    this.page = 1,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [podcastId, page, pageSize];
}
