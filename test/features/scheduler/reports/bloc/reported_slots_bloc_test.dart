import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/features/podcasts/data/data_sources/podcast_data_source.dart'
    show PaginatedResponse;
import 'package:streamwatch_frontend/features/scheduler/reports/bloc/reported_slots_bloc.dart';
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

void main() {
  late MockReportsDataSource ds;

  setUp(() {
    ds = MockReportsDataSource();
  });

  group('ReportedSlotsBloc', () {
    blocTest<ReportedSlotsBloc, ReportedSlotsState>(
      'fetch page 1 happy: Loading -> Loaded',
      build: () {
        when(() => ds.expectedTodayScheduleSlots(
                page: any(named: 'page'), pageSize: any(named: 'pageSize')))
            .thenAnswer((_) async => Right(PaginatedResponse(
                  items: [_slot('s1'), _slot('s2')],
                  total: 2,
                  page: 1,
                  pageSize: 50,
                )));
        return ReportedSlotsBloc(dataSource: ds);
      },
      act: (b) => b.add(const FetchReportedSlotsEvent(reportKey: 'expected-today')),
      expect: () => [
        const ReportedSlotsLoading(),
        isA<ReportedSlotsLoaded>()
            .having((s) => s.slots.length, 'slots', 2)
            .having((s) => s.hasMore, 'hasMore', false)
            .having((s) => s.reportKey, 'reportKey', 'expected-today')
            .having((s) => s.currentPage, 'currentPage', 1),
      ],
    );

    blocTest<ReportedSlotsBloc, ReportedSlotsState>(
      'page 2 appends without emitting Loading',
      build: () {
        when(() => ds.lateScheduleSlots(
                page: any(named: 'page'), pageSize: any(named: 'pageSize')))
            .thenAnswer((_) async => Right(PaginatedResponse(
                  items: [_slot('s3')],
                  total: 3,
                  page: 2,
                  pageSize: 1,
                )));
        return ReportedSlotsBloc(dataSource: ds);
      },
      seed: () => ReportedSlotsLoaded(
        reportKey: 'late',
        slots: [_slot('s1'), _slot('s2')],
        hasMore: true,
        currentPage: 1,
      ),
      act: (b) => b.add(
          const FetchReportedSlotsEvent(reportKey: 'late', page: 2)),
      expect: () => [
        isA<ReportedSlotsLoaded>()
            .having((s) => s.slots.length, 'slots', 3)
            .having((s) => s.currentPage, 'currentPage', 2),
      ],
    );

    blocTest<ReportedSlotsBloc, ReportedSlotsState>(
      'failure maps to Error state',
      build: () {
        when(() => ds.expectedTodayScheduleSlots(
                page: any(named: 'page'), pageSize: any(named: 'pageSize')))
            .thenAnswer((_) async => const Left(GeneralFailure('network')));
        return ReportedSlotsBloc(dataSource: ds);
      },
      act: (b) => b.add(const FetchReportedSlotsEvent(reportKey: 'expected-today')),
      expect: () => [
        const ReportedSlotsLoading(),
        const ReportedSlotsError('network'),
      ],
    );

    blocTest<ReportedSlotsBloc, ReportedSlotsState>(
      'unknown slug emits Error state',
      build: () => ReportedSlotsBloc(dataSource: ds),
      act: (b) =>
          b.add(const FetchReportedSlotsEvent(reportKey: 'not-a-slug')),
      expect: () => [
        const ReportedSlotsLoading(),
        isA<ReportedSlotsError>(),
      ],
    );
  });
}
