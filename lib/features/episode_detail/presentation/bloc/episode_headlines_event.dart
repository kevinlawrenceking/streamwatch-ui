part of 'episode_headlines_bloc.dart';

abstract class EpisodeHeadlinesEvent extends Equatable {
  const EpisodeHeadlinesEvent();
  @override
  List<Object?> get props => [];
}

class LoadHeadlinesEvent extends EpisodeHeadlinesEvent {
  final String episodeId;
  const LoadHeadlinesEvent(this.episodeId);
  @override
  List<Object?> get props => [episodeId];
}

class CreateHeadlineEvent extends EpisodeHeadlinesEvent {
  final String episodeId;
  final Map<String, dynamic> body;
  const CreateHeadlineEvent({required this.episodeId, required this.body});
  @override
  List<Object?> get props => [episodeId, body];
}

class DeleteHeadlineEvent extends EpisodeHeadlinesEvent {
  final String candidateId;
  const DeleteHeadlineEvent(this.candidateId);
  @override
  List<Object?> get props => [candidateId];
}

class ApproveHeadlineEvent extends EpisodeHeadlinesEvent {
  final String candidateId;

  /// Optional episodeId so the bloc can dispatch LoadHeadlinesEvent on the
  /// 409 race path (auto-refetch per Lock #8). Null is tolerated; only the
  /// specific message will surface and the caller can manually refresh.
  final String? episodeId;
  const ApproveHeadlineEvent({required this.candidateId, this.episodeId});
  @override
  List<Object?> get props => [candidateId, episodeId];
}

class GenerateHeadlinesEvent extends EpisodeHeadlinesEvent {
  final String episodeId;
  const GenerateHeadlinesEvent(this.episodeId);
  @override
  List<Object?> get props => [episodeId];
}

class EpisodeHeadlinesErrorAcknowledged extends EpisodeHeadlinesEvent {
  const EpisodeHeadlinesErrorAcknowledged();
}
