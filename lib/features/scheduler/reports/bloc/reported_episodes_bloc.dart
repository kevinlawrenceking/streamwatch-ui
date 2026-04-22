import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/errors/failures/failure.dart';
import '../../../podcasts/data/data_sources/podcast_data_source.dart'
    show PaginatedResponse;
import '../../../podcasts/data/models/podcast_episode.dart';
import '../data/data_sources/reports_data_source.dart';
import 'reports_dashboard_bloc.dart';

part 'reported_episodes_event.dart';
part 'reported_episodes_state.dart';

/// Bloc for the episode-valued drill-downs (recent, transcript-pending,
/// headline-ready, pending-review, pending-clip-request).
///
/// Behaviors:
///   - Infinite-scroll load-more mirrors EpisodeListBloc (page 2+ appends).
///   - Inline actions (mark-reviewed, request-clip) use an optimistic pattern:
///     episode id is added to [inFlightEpisodeIds] while the request is in
///     flight (UX indicator + re-entry guard). On success the episode is
///     permanently removed from the list, `dashboardBloc` is notified to
///     refresh counts. On failure the episode is retained and
///     [lastActionError] is surfaced for a SnackBar via BlocListener.
///
/// `dashboardBloc` is constructor-injected (D4) — do not resolve via GetIt
/// inside event handlers.
class ReportedEpisodesBloc
    extends Bloc<ReportedEpisodesEvent, ReportedEpisodesState> {
  final IReportsDataSource _dataSource;
  final ReportsDashboardBloc _dashboardBloc;

  ReportedEpisodesBloc({
    required IReportsDataSource dataSource,
    required ReportsDashboardBloc dashboardBloc,
  })  : _dataSource = dataSource,
        _dashboardBloc = dashboardBloc,
        super(const ReportedEpisodesInitial()) {
    on<FetchReportedEpisodesEvent>(_onFetch);
    on<MarkReviewedRequestedEvent>(_onMarkReviewed);
    on<RequestClipRequestedEvent>(_onRequestClip);
    on<ActionErrorAcknowledgedEvent>(_onActionErrorAcknowledged);
  }

  Future<void> _onFetch(
    FetchReportedEpisodesEvent event,
    Emitter<ReportedEpisodesState> emit,
  ) async {
    final currentState = state;
    final isLoadMore =
        event.page > 1 && currentState is ReportedEpisodesLoaded;

    if (!isLoadMore) {
      emit(const ReportedEpisodesLoading());
    }

    final result = await _fetchForSlug(
      event.reportKey,
      page: event.page,
      pageSize: event.pageSize,
    );

    result.fold(
      (failure) => emit(ReportedEpisodesError(failure.message)),
      (response) {
        final allEpisodes = isLoadMore
            ? [...currentState.episodes, ...response.items]
            : response.items;
        final preservedInFlight = isLoadMore
            ? currentState.inFlightEpisodeIds
            : const <String>{};
        emit(ReportedEpisodesLoaded(
          reportKey: event.reportKey,
          episodes: allEpisodes,
          hasMore: response.hasMore,
          currentPage: event.page,
          inFlightEpisodeIds: preservedInFlight,
        ));
      },
    );
  }

  Future<void> _onMarkReviewed(
    MarkReviewedRequestedEvent event,
    Emitter<ReportedEpisodesState> emit,
  ) =>
      _handleEpisodeAction(
        emit,
        episodeId: event.episodeId,
        action: _dataSource.markEpisodeReviewed,
      );

  Future<void> _onRequestClip(
    RequestClipRequestedEvent event,
    Emitter<ReportedEpisodesState> emit,
  ) =>
      _handleEpisodeAction(
        emit,
        episodeId: event.episodeId,
        action: _dataSource.requestEpisodeClip,
      );

  Future<void> _handleEpisodeAction(
    Emitter<ReportedEpisodesState> emit, {
    required String episodeId,
    required Future<Either<Failure, PodcastEpisodeModel>> Function(String) action,
  }) async {
    final currentState = state;
    if (currentState is! ReportedEpisodesLoaded) return;
    if (currentState.inFlightEpisodeIds.contains(episodeId)) return;

    // Mark in-flight.
    emit(currentState.copyWith(
      inFlightEpisodeIds: {...currentState.inFlightEpisodeIds, episodeId},
      clearLastActionError: true,
    ));

    final result = await action(episodeId);

    final afterState = state;
    if (afterState is! ReportedEpisodesLoaded) return;

    result.fold(
      (failure) {
        final nextInFlight = {...afterState.inFlightEpisodeIds}..remove(episodeId);
        emit(afterState.copyWith(
          inFlightEpisodeIds: nextInFlight,
          lastActionError: failure.message,
        ));
      },
      (_) {
        final nextInFlight = {...afterState.inFlightEpisodeIds}..remove(episodeId);
        final nextEpisodes =
            afterState.episodes.where((e) => e.id != episodeId).toList();
        emit(afterState.copyWith(
          episodes: nextEpisodes,
          inFlightEpisodeIds: nextInFlight,
          clearLastActionError: true,
        ));
        _dashboardBloc.add(const RefreshReportsDashboard());
      },
    );
  }

  void _onActionErrorAcknowledged(
    ActionErrorAcknowledgedEvent event,
    Emitter<ReportedEpisodesState> emit,
  ) {
    final currentState = state;
    if (currentState is! ReportedEpisodesLoaded) return;
    if (currentState.lastActionError == null) return;
    emit(currentState.copyWith(clearLastActionError: true));
  }

  Future<Either<Failure, PaginatedResponse<PodcastEpisodeModel>>> _fetchForSlug(
    String slug, {
    required int page,
    required int pageSize,
  }) {
    switch (slug) {
      case 'recent':
        return _dataSource.recentEpisodes(page: page, pageSize: pageSize);
      case 'transcript-pending':
        return _dataSource.transcriptPendingEpisodes(
            page: page, pageSize: pageSize);
      case 'headline-ready':
        return _dataSource.headlineReadyEpisodes(
            page: page, pageSize: pageSize);
      case 'pending-review':
        return _dataSource.pendingReviewEpisodes(
            page: page, pageSize: pageSize);
      case 'pending-clip-request':
        return _dataSource.pendingClipRequestEpisodes(
            page: page, pageSize: pageSize);
      default:
        return Future.value(
          Left(GeneralFailure('Unknown episode report slug: $slug')),
        );
    }
  }
}
