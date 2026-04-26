part of 'episode_transcripts_bloc.dart';

/// Events for the EpisodeTranscripts BLoC.
abstract class EpisodeTranscriptsEvent extends Equatable {
  const EpisodeTranscriptsEvent();
  @override
  List<Object?> get props => [];
}

/// Load all transcripts for an episode.
class LoadTranscriptsEvent extends EpisodeTranscriptsEvent {
  final String episodeId;
  const LoadTranscriptsEvent(this.episodeId);
  @override
  List<Object?> get props => [episodeId];
}

/// Create a new transcript variant for an episode.
class CreateTranscriptEvent extends EpisodeTranscriptsEvent {
  final String episodeId;
  final Map<String, dynamic> body;
  const CreateTranscriptEvent({required this.episodeId, required this.body});
  @override
  List<Object?> get props => [episodeId, body];
}

/// Patch an existing transcript (text/json/etc).
class PatchTranscriptEvent extends EpisodeTranscriptsEvent {
  final String transcriptId;
  final Map<String, dynamic> body;
  const PatchTranscriptEvent({required this.transcriptId, required this.body});
  @override
  List<Object?> get props => [transcriptId, body];
}

/// Hard-delete a transcript by id.
class DeleteTranscriptEvent extends EpisodeTranscriptsEvent {
  final String transcriptId;
  const DeleteTranscriptEvent(this.transcriptId);
  @override
  List<Object?> get props => [transcriptId];
}

/// Promote a transcript to primary (transactional on the server).
class SetPrimaryTranscriptEvent extends EpisodeTranscriptsEvent {
  final String transcriptId;
  const SetPrimaryTranscriptEvent(this.transcriptId);
  @override
  List<Object?> get props => [transcriptId];
}

/// Clear lastActionError after SnackBar surfaces it.
class EpisodeTranscriptsErrorAcknowledged extends EpisodeTranscriptsEvent {
  const EpisodeTranscriptsErrorAcknowledged();
}
