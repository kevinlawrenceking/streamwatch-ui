part of 'reported_episodes_bloc.dart';

abstract class ReportedEpisodesEvent extends Equatable {
  const ReportedEpisodesEvent();

  @override
  List<Object?> get props => [];
}

class FetchReportedEpisodesEvent extends ReportedEpisodesEvent {
  final String reportKey;
  final int page;
  final int pageSize;

  const FetchReportedEpisodesEvent({
    required this.reportKey,
    this.page = 1,
    this.pageSize = 50,
  });

  @override
  List<Object?> get props => [reportKey, page, pageSize];
}

class MarkReviewedRequestedEvent extends ReportedEpisodesEvent {
  final String episodeId;
  const MarkReviewedRequestedEvent(this.episodeId);

  @override
  List<Object?> get props => [episodeId];
}

class RequestClipRequestedEvent extends ReportedEpisodesEvent {
  final String episodeId;
  const RequestClipRequestedEvent(this.episodeId);

  @override
  List<Object?> get props => [episodeId];
}

/// View dispatches this after showing the SnackBar for a non-null
/// [ReportedEpisodesLoaded.lastActionError] so the same error is not shown
/// a second time on any subsequent rebuild.
class ActionErrorAcknowledgedEvent extends ReportedEpisodesEvent {
  const ActionErrorAcknowledgedEvent();
}
