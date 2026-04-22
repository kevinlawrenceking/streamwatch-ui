import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/features/podcasts/data/data_sources/podcast_data_source.dart'
    show PaginatedResponse;
import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_episode.dart';
import 'package:streamwatch_frontend/features/scheduler/reports/bloc/reported_episodes_bloc.dart';
import 'package:streamwatch_frontend/features/scheduler/reports/bloc/reports_dashboard_bloc.dart';
import 'package:streamwatch_frontend/features/scheduler/reports/data/data_sources/reports_data_source.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockReportsDataSource extends Mock implements IReportsDataSource {}

class MockReportsDashboardBloc extends Mock implements ReportsDashboardBloc {}

PodcastEpisodeModel _ep(String id,
        {String? ts = 'ready', DateTime? reviewedAt}) =>
    PodcastEpisodeModel(
      id: id,
      podcastId: 'p',
      title: 'Episode $id',
      createdAt: DateTime(2026, 4, 20),
      transcriptStatus: ts,
      reviewedAt: reviewedAt,
    );

void main() {
  late MockReportsDataSource ds;
  late MockReportsDashboardBloc dashBloc;

  setUpAll(() {
    registerFallbackValue(const RefreshReportsDashboard());
  });

  setUp(() {
    ds = MockReportsDataSource();
    dashBloc = MockReportsDashboardBloc();
  });

  ReportedEpisodesBloc build() => ReportedEpisodesBloc(
        dataSource: ds,
        dashboardBloc: dashBloc,
      );

  group('ReportedEpisodesBloc — fetch', () {
    blocTest<ReportedEpisodesBloc, ReportedEpisodesState>(
      'page 1 happy: Loading -> Loaded',
      build: () {
        when(() => ds.pendingReviewEpisodes(
                page: any(named: 'page'),
                pageSize: any(named: 'pageSize')))
            .thenAnswer((_) async => Right(PaginatedResponse(
                  items: [_ep('a'), _ep('b')],
                  total: 2,
                  page: 1,
                  pageSize: 50,
                )));
        return build();
      },
      act: (b) =>
          b.add(const FetchReportedEpisodesEvent(reportKey: 'pending-review')),
      expect: () => [
        const ReportedEpisodesLoading(),
        isA<ReportedEpisodesLoaded>()
            .having((s) => s.episodes.length, 'episodes', 2)
            .having((s) => s.reportKey, 'reportKey', 'pending-review')
            .having((s) => s.inFlightEpisodeIds, 'empty in-flight', isEmpty),
      ],
    );

    blocTest<ReportedEpisodesBloc, ReportedEpisodesState>(
      'page 2 appends without Loading, preserves in-flight set',
      build: () {
        when(() => ds.recentEpisodes(
                page: any(named: 'page'),
                pageSize: any(named: 'pageSize'),
                hours: any(named: 'hours')))
            .thenAnswer((_) async => Right(PaginatedResponse(
                  items: [_ep('c')],
                  total: 3,
                  page: 2,
                  pageSize: 1,
                )));
        return build();
      },
      seed: () => ReportedEpisodesLoaded(
        reportKey: 'recent',
        episodes: [_ep('a'), _ep('b')],
        hasMore: true,
        currentPage: 1,
        inFlightEpisodeIds: const {'a'},
      ),
      act: (b) => b.add(
          const FetchReportedEpisodesEvent(reportKey: 'recent', page: 2)),
      expect: () => [
        isA<ReportedEpisodesLoaded>()
            .having((s) => s.episodes.length, 'episodes', 3)
            .having((s) => s.currentPage, 'currentPage', 2)
            .having((s) => s.inFlightEpisodeIds, 'in-flight preserved',
                equals({'a'})),
      ],
    );
  });

  group('ReportedEpisodesBloc — mark reviewed', () {
    blocTest<ReportedEpisodesBloc, ReportedEpisodesState>(
      'success: removes episode from list + refreshes dashboard',
      build: () {
        when(() => ds.markEpisodeReviewed('a'))
            .thenAnswer((_) async => Right(_ep('a')));
        return build();
      },
      seed: () => ReportedEpisodesLoaded(
        reportKey: 'pending-review',
        episodes: [_ep('a'), _ep('b')],
        hasMore: false,
        currentPage: 1,
      ),
      act: (b) => b.add(const MarkReviewedRequestedEvent('a')),
      expect: () => [
        isA<ReportedEpisodesLoaded>()
            .having((s) => s.inFlightEpisodeIds, 'in-flight add',
                equals({'a'}))
            .having((s) => s.episodes.length, 'episodes unchanged in flight',
                2),
        isA<ReportedEpisodesLoaded>()
            .having((s) => s.episodes.length, 'episode removed', 1)
            .having((s) => s.episodes.first.id, 'remaining id', 'b')
            .having((s) => s.inFlightEpisodeIds, 'in-flight cleared',
                isEmpty)
            .having((s) => s.lastActionError, 'no error', isNull),
      ],
      verify: (_) {
        verify(() => dashBloc.add(const RefreshReportsDashboard())).called(1);
      },
    );

    blocTest<ReportedEpisodesBloc, ReportedEpisodesState>(
      'failure: keeps episode + surfaces lastActionError + no dashboard refresh',
      build: () {
        when(() => ds.markEpisodeReviewed('a')).thenAnswer((_) async =>
            const Left(HttpFailure(statusCode: 409, message: 'conflict')));
        return build();
      },
      seed: () => ReportedEpisodesLoaded(
        reportKey: 'pending-review',
        episodes: [_ep('a'), _ep('b')],
        hasMore: false,
        currentPage: 1,
      ),
      act: (b) => b.add(const MarkReviewedRequestedEvent('a')),
      expect: () => [
        isA<ReportedEpisodesLoaded>()
            .having((s) => s.inFlightEpisodeIds, 'marked in-flight',
                equals({'a'})),
        isA<ReportedEpisodesLoaded>()
            .having((s) => s.episodes.length, 'episode retained', 2)
            .having((s) => s.inFlightEpisodeIds, 'in-flight cleared',
                isEmpty)
            .having((s) => s.lastActionError, 'error surfaced', 'conflict'),
      ],
      verify: (_) {
        verifyNever(() => dashBloc.add(any()));
      },
    );

    blocTest<ReportedEpisodesBloc, ReportedEpisodesState>(
      're-entry guard: second tap on same id while in-flight is a noop',
      build: () => build(),
      seed: () => ReportedEpisodesLoaded(
        reportKey: 'pending-review',
        episodes: [_ep('a')],
        hasMore: false,
        currentPage: 1,
        inFlightEpisodeIds: const {'a'},
      ),
      act: (b) => b.add(const MarkReviewedRequestedEvent('a')),
      expect: () => <ReportedEpisodesState>[],
      verify: (_) {
        verifyNever(() => ds.markEpisodeReviewed(any()));
      },
    );
  });

  group('ReportedEpisodesBloc — request clip', () {
    blocTest<ReportedEpisodesBloc, ReportedEpisodesState>(
      'success removes + refreshes dashboard',
      build: () {
        when(() => ds.requestEpisodeClip('a'))
            .thenAnswer((_) async => Right(_ep('a')));
        return build();
      },
      seed: () => ReportedEpisodesLoaded(
        reportKey: 'recent',
        episodes: [_ep('a'), _ep('b')],
        hasMore: false,
        currentPage: 1,
      ),
      act: (b) => b.add(const RequestClipRequestedEvent('a')),
      expect: () => [
        isA<ReportedEpisodesLoaded>().having(
            (s) => s.inFlightEpisodeIds, 'in-flight add', equals({'a'})),
        isA<ReportedEpisodesLoaded>()
            .having((s) => s.episodes.length, 'episode removed', 1)
            .having((s) => s.inFlightEpisodeIds, 'cleared', isEmpty),
      ],
      verify: (_) {
        verify(() => dashBloc.add(const RefreshReportsDashboard())).called(1);
      },
    );
  });

  group('ReportedEpisodesBloc — ack', () {
    blocTest<ReportedEpisodesBloc, ReportedEpisodesState>(
      'ActionErrorAcknowledgedEvent clears lastActionError',
      build: () => build(),
      seed: () => ReportedEpisodesLoaded(
        reportKey: 'recent',
        episodes: [_ep('a')],
        hasMore: false,
        currentPage: 1,
        lastActionError: 'oops',
      ),
      act: (b) => b.add(const ActionErrorAcknowledgedEvent()),
      expect: () => [
        isA<ReportedEpisodesLoaded>()
            .having((s) => s.lastActionError, 'cleared', isNull),
      ],
    );
  });

  group('ReportedEpisodesBloc — equality', () {
    test('Loaded Equatable: Set<String> equal via sorted .toList() in props',
        () {
      final a = ReportedEpisodesLoaded(
        reportKey: 'recent',
        episodes: [_ep('x')],
        hasMore: false,
        currentPage: 1,
        inFlightEpisodeIds: const {'c', 'a', 'b'},
      );
      final b = ReportedEpisodesLoaded(
        reportKey: 'recent',
        episodes: [_ep('x')],
        hasMore: false,
        currentPage: 1,
        inFlightEpisodeIds: const {'a', 'b', 'c'},
      );
      expect(a, equals(b));
    });
  });
}
