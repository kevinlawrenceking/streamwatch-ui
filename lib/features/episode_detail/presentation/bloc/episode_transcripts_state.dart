part of 'episode_transcripts_bloc.dart';

abstract class EpisodeTranscriptsState extends Equatable {
  const EpisodeTranscriptsState();
  @override
  List<Object?> get props => [];
}

class EpisodeTranscriptsInitial extends EpisodeTranscriptsState {
  const EpisodeTranscriptsInitial();
}

class EpisodeTranscriptsLoading extends EpisodeTranscriptsState {
  const EpisodeTranscriptsLoading();
}

class EpisodeTranscriptsLoaded extends EpisodeTranscriptsState {
  final List<PodcastTranscriptModel> transcripts;
  final bool isMutating;
  final String? lastActionError;

  const EpisodeTranscriptsLoaded({
    required this.transcripts,
    this.isMutating = false,
    this.lastActionError,
  });

  EpisodeTranscriptsLoaded copyWith({
    List<PodcastTranscriptModel>? transcripts,
    bool? isMutating,
    String? lastActionError,
    bool clearLastActionError = false,
  }) {
    return EpisodeTranscriptsLoaded(
      transcripts: transcripts ?? this.transcripts,
      isMutating: isMutating ?? this.isMutating,
      lastActionError: clearLastActionError
          ? null
          : (lastActionError ?? this.lastActionError),
    );
  }

  @override
  List<Object?> get props => [transcripts, isMutating, lastActionError];
}

class EpisodeTranscriptsError extends EpisodeTranscriptsState {
  final String message;
  const EpisodeTranscriptsError(this.message);
  @override
  List<Object?> get props => [message];
}
