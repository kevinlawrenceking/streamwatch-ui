import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/features/podcasts/data/data_sources/podcast_data_source.dart'
    show PaginatedResponse;
import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_episode.dart';
import 'package:streamwatch_frontend/features/scheduler/reports/bloc/reports_dashboard_bloc.dart';
import 'package:streamwatch_frontend/features/scheduler/reports/data/data_sources/reports_data_source.dart';
import 'package:streamwatch_frontend/features/scheduler/reports/data/models/podcast_schedule_slot.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockReportsDataSource extends Mock implements IReportsDataSource {}

PodcastScheduleSlot _slot(String id) => PodcastScheduleSlot(
      id: id,
      podcastId: 'p',
      source: 'csv_import',
      isActive: true,
      createdAt: DateTime(2026, 4, 20),
      updatedAt: DateTime(2026, 4, 20),
    );

PodcastEpisodeModel _ep(String id) => PodcastEpisodeModel(
      id: id,
      podcastId: 'p',
      title: 't',
      createdAt: DateTime(2026, 4, 20),
    );

PaginatedResponse<PodcastScheduleSlot> _slotPage(int total) =>
    PaginatedResponse<PodcastScheduleSlot>(
        items: [_slot('x')], total: total, page: 1, pageSize: 1);

PaginatedResponse<PodcastEpisodeModel> _epPage(int total) =>
    PaginatedResponse<PodcastEpisodeModel>(
        items: [_ep('x')], total: total, page: 1, pageSize: 1);

void _stubAll(MockReportsDataSource ds,
    {int expectedToday = 1,
    int late = 2,
    int recent = 3,
    int transcriptPending = 4,
    int headlineReady = 5,
    int pendingReview = 6,
    int pendingClipRequest = 7}) {
  when(() => ds.expectedTodayScheduleSlots(
          page: any(named: 'page'), pageSize: any(named: 'pageSize')))
      .thenAnswer((_) async => Right(_slotPage(expectedToday)));
  when(() => ds.lateScheduleSlots(
          page: any(named: 'page'), pageSize: any(named: 'pageSize')))
      .thenAnswer((_) async => Right(_slotPage(late)));
  when(() => ds.recentEpisodes(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          hours: any(named: 'hours')))
      .thenAnswer((_) async => Right(_epPage(recent)));
  when(() => ds.transcriptPendingEpisodes(
          page: any(named: 'page'), pageSize: any(named: 'pageSize')))
      .thenAnswer((_) async => Right(_epPage(transcriptPending)));
  when(() => ds.headlineReadyEpisodes(
          page: any(named: 'page'), pageSize: any(named: 'pageSize')))
      .thenAnswer((_) async => Right(_epPage(headlineReady)));
  when(() => ds.pendingReviewEpisodes(
          page: any(named: 'page'), pageSize: any(named: 'pageSize')))
      .thenAnswer((_) async => Right(_epPage(pendingReview)));
  when(() => ds.pendingClipRequestEpisodes(
          page: any(named: 'page'), pageSize: any(named: 'pageSize')))
      .thenAnswer((_) async => Right(_epPage(pendingClipRequest)));
}

void main() {
  late MockReportsDataSource ds;

  setUp(() {
    ds = MockReportsDataSource();
  });

  group('ReportsDashboardBloc', () {
    blocTest<ReportsDashboardBloc, ReportsDashboardState>(
      'happy path: emits Loading then Loaded with 7 counts + empty errors',
      build: () {
        _stubAll(ds);
        return ReportsDashboardBloc(dataSource: ds);
      },
      act: (b) => b.add(const LoadReportsDashboard()),
      expect: () => [
        const ReportsDashboardLoading(),
        isA<ReportsDashboardLoaded>()
            .having((s) => s.counts.length, 'counts.length', 7)
            .having((s) => s.errors, 'errors empty', isEmpty)
            .having((s) => s.counts['expected-today'], 'expected-today', 1)
            .having((s) => s.counts['late'], 'late', 2)
            .having((s) => s.counts['recent'], 'recent', 3)
            .having((s) => s.counts['pending-clip-request'],
                'pending-clip-request', 7),
      ],
    );

    blocTest<ReportsDashboardBloc, ReportsDashboardState>(
      'per-slug error isolation: one failure leaves other 6 counts intact',
      build: () {
        _stubAll(ds);
        when(() => ds.recentEpisodes(
                page: any(named: 'page'),
                pageSize: any(named: 'pageSize'),
                hours: any(named: 'hours')))
            .thenAnswer((_) async => const Left(GeneralFailure('boom')));
        return ReportsDashboardBloc(dataSource: ds);
      },
      act: (b) => b.add(const LoadReportsDashboard()),
      expect: () => [
        const ReportsDashboardLoading(),
        isA<ReportsDashboardLoaded>()
            .having((s) => s.counts.length, 'counts.length', 6)
            .having((s) => s.errors.length, 'errors.length', 1)
            .having((s) => s.errors['recent'], 'recent error', 'boom')
            .having((s) => s.counts.containsKey('recent'),
                'recent not in counts', isFalse),
      ],
    );

    blocTest<ReportsDashboardBloc, ReportsDashboardState>(
      'Refresh re-fires all 7 and emits new Loaded without Loading',
      build: () {
        _stubAll(ds);
        return ReportsDashboardBloc(dataSource: ds);
      },
      seed: () => const ReportsDashboardLoaded(counts: {}, errors: {}),
      act: (b) => b.add(const RefreshReportsDashboard()),
      expect: () => [
        isA<ReportsDashboardLoaded>()
            .having((s) => s.counts.length, 'counts.length', 7),
      ],
    );

    test('Loaded Equatable equality: identical counts+errors maps', () {
      const a = ReportsDashboardLoaded(
          counts: {'late': 2}, errors: {'recent': 'x'});
      const b = ReportsDashboardLoaded(
          counts: {'late': 2}, errors: {'recent': 'x'});
      expect(a, equals(b));
    });
  });
}
