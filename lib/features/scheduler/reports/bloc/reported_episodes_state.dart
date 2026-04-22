part of 'reported_episodes_bloc.dart';

abstract class ReportedEpisodesState extends Equatable {
  const ReportedEpisodesState();

  @override
  List<Object?> get props => [];
}

class ReportedEpisodesInitial extends ReportedEpisodesState {
  const ReportedEpisodesInitial();
}

class ReportedEpisodesLoading extends ReportedEpisodesState {
  const ReportedEpisodesLoading();
}

class ReportedEpisodesLoaded extends ReportedEpisodesState {
  final String reportKey;
  final List<PodcastEpisodeModel> episodes;
  final bool hasMore;
  final int currentPage;

  /// Episode ids currently awaiting a mark-reviewed or request-clip response.
  /// Serves as both a UX indicator (disabled button + spinner on the card)
  /// and a re-entry guard (second tap is noop while in flight).
  final Set<String> inFlightEpisodeIds;

  /// Non-null after a failed optimistic action — view's BlocListener shows a
  /// SnackBar and then dispatches ActionErrorAcknowledgedEvent to clear.
  final String? lastActionError;

  const ReportedEpisodesLoaded({
    required this.reportKey,
    required this.episodes,
    required this.hasMore,
    this.currentPage = 1,
    this.inFlightEpisodeIds = const <String>{},
    this.lastActionError,
  });

  ReportedEpisodesLoaded copyWith({
    String? reportKey,
    List<PodcastEpisodeModel>? episodes,
    bool? hasMore,
    int? currentPage,
    Set<String>? inFlightEpisodeIds,
    String? lastActionError,
    bool clearLastActionError = false,
  }) {
    return ReportedEpisodesLoaded(
      reportKey: reportKey ?? this.reportKey,
      episodes: episodes ?? this.episodes,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      inFlightEpisodeIds: inFlightEpisodeIds ?? this.inFlightEpisodeIds,
      lastActionError: clearLastActionError
          ? null
          : (lastActionError ?? this.lastActionError),
    );
  }

  @override
  List<Object?> get props => [
        reportKey,
        episodes,
        hasMore,
        currentPage,
        // Sorted list for deterministic Equatable comparison (Set equality in
        // Dart is not by default value-based in Equatable props lists).
        inFlightEpisodeIds.toList()..sort(),
        lastActionError,
      ];
}

class ReportedEpisodesError extends ReportedEpisodesState {
  final String message;
  const ReportedEpisodesError(this.message);

  @override
  List<Object?> get props => [message];
}
