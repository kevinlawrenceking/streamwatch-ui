part of 'episode_headlines_bloc.dart';

abstract class EpisodeHeadlinesState extends Equatable {
  const EpisodeHeadlinesState();
  @override
  List<Object?> get props => [];
}

class EpisodeHeadlinesInitial extends EpisodeHeadlinesState {
  const EpisodeHeadlinesInitial();
}

class EpisodeHeadlinesLoading extends EpisodeHeadlinesState {
  const EpisodeHeadlinesLoading();
}

class EpisodeHeadlinesLoaded extends EpisodeHeadlinesState {
  final List<PodcastHeadlineCandidateModel> candidates;
  final bool isMutating;

  /// True from the moment GenerateHeadlinesEvent dispatches a 202-Accepted
  /// request until the user manually refreshes the tab. Per Lock #5 the bloc
  /// does not poll; this flag is purely a UX indicator.
  final bool isGenerating;
  final String? lastActionError;

  const EpisodeHeadlinesLoaded({
    required this.candidates,
    this.isMutating = false,
    this.isGenerating = false,
    this.lastActionError,
  });

  EpisodeHeadlinesLoaded copyWith({
    List<PodcastHeadlineCandidateModel>? candidates,
    bool? isMutating,
    bool? isGenerating,
    String? lastActionError,
    bool clearLastActionError = false,
  }) {
    return EpisodeHeadlinesLoaded(
      candidates: candidates ?? this.candidates,
      isMutating: isMutating ?? this.isMutating,
      isGenerating: isGenerating ?? this.isGenerating,
      lastActionError: clearLastActionError
          ? null
          : (lastActionError ?? this.lastActionError),
    );
  }

  @override
  List<Object?> get props =>
      [candidates, isMutating, isGenerating, lastActionError];
}

class EpisodeHeadlinesError extends EpisodeHeadlinesState {
  final String message;
  const EpisodeHeadlinesError(this.message);
  @override
  List<Object?> get props => [message];
}
