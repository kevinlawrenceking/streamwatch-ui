part of 'episode_detail_bloc.dart';

/// States for the EpisodeDetail BLoC.
abstract class EpisodeDetailState extends Equatable {
  const EpisodeDetailState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any load.
class EpisodeDetailInitial extends EpisodeDetailState {
  const EpisodeDetailInitial();
}

/// Loading state during initial fetch.
class EpisodeDetailLoading extends EpisodeDetailState {
  const EpisodeDetailLoading();
}

/// Loaded state with the current episode + optional in-flight + error fields.
class EpisodeDetailLoaded extends EpisodeDetailState {
  final PodcastEpisodeModel episode;
  final bool isMutating;
  final String? lastActionError;

  const EpisodeDetailLoaded({
    required this.episode,
    this.isMutating = false,
    this.lastActionError,
  });

  EpisodeDetailLoaded copyWith({
    PodcastEpisodeModel? episode,
    bool? isMutating,
    String? lastActionError,
    bool clearLastActionError = false,
  }) {
    return EpisodeDetailLoaded(
      episode: episode ?? this.episode,
      isMutating: isMutating ?? this.isMutating,
      lastActionError: clearLastActionError
          ? null
          : (lastActionError ?? this.lastActionError),
    );
  }

  @override
  List<Object?> get props => [episode, isMutating, lastActionError];
}

/// Error state for the initial load.
class EpisodeDetailError extends EpisodeDetailState {
  final String message;
  const EpisodeDetailError(this.message);
  @override
  List<Object?> get props => [message];
}
