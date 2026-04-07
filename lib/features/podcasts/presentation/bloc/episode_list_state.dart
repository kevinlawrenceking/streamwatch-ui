part of 'episode_list_bloc.dart';

/// States for the EpisodeList BLoC.
abstract class EpisodeListState extends Equatable {
  const EpisodeListState();

  @override
  List<Object?> get props => [];
}

/// Initial state before episodes are loaded.
class EpisodeListInitial extends EpisodeListState {
  const EpisodeListInitial();
}

/// Loading state while fetching episodes.
class EpisodeListLoading extends EpisodeListState {
  const EpisodeListLoading();
}

/// Episodes loaded successfully.
class EpisodeListLoaded extends EpisodeListState {
  final List<PodcastEpisodeModel> episodes;
  final bool hasMore;
  final int currentPage;

  const EpisodeListLoaded({
    required this.episodes,
    required this.hasMore,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props => [episodes, hasMore, currentPage];
}

/// Error state when loading episodes fails.
class EpisodeListError extends EpisodeListState {
  final String message;

  const EpisodeListError(this.message);

  @override
  List<Object?> get props => [message];
}
