import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/features/podcasts/data/data_sources/podcast_data_source.dart';
import 'package:streamwatch_frontend/features/podcasts/data/models/podcast.dart';
import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_platform.dart';
import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_schedule.dart';
import 'package:streamwatch_frontend/features/podcasts/presentation/bloc/podcast_detail_bloc.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockPodcastDataSource extends Mock implements IPodcastDataSource {}

void main() {
  late MockPodcastDataSource mockDataSource;

  final testPodcast = PodcastModel(
    id: 'p1',
    name: 'Test Podcast',
    description: 'Description',
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
  );

  const testPlatform = PodcastPlatformModel(
    id: 'pl1',
    podcastId: 'p1',
    platformName: 'Spotify',
    platformUrl: 'https://spotify.com/show/test',
  );

  const testSchedule = PodcastScheduleModel(
    id: 's1',
    podcastId: 'p1',
    dayOfWeek: 'monday',
    startTime: '09:00',
    endTime: '10:00',
    timezone: 'America/Los_Angeles',
  );

  setUp(() {
    mockDataSource = MockPodcastDataSource();
  });

  group('PodcastDetailBloc', () {
    blocTest<PodcastDetailBloc, PodcastDetailState>(
      'emits [Loading, Loaded] when FetchDetail succeeds',
      build: () {
        when(() => mockDataSource.getPodcast('p1'))
            .thenAnswer((_) async => Right(testPodcast));
        when(() => mockDataSource.listPlatforms('p1'))
            .thenAnswer((_) async => Right([testPlatform]));
        when(() => mockDataSource.listSchedules('p1'))
            .thenAnswer((_) async => Right([testSchedule]));
        return PodcastDetailBloc(dataSource: mockDataSource);
      },
      act: (bloc) => bloc.add(const FetchPodcastDetailEvent('p1')),
      expect: () => [
        const PodcastDetailLoading(),
        PodcastDetailLoaded(
          podcast: testPodcast,
          platforms: [testPlatform],
          schedules: [testSchedule],
        ),
      ],
    );

    blocTest<PodcastDetailBloc, PodcastDetailState>(
      'emits [Loading, Error] when FetchDetail fails',
      build: () {
        when(() => mockDataSource.getPodcast('p1')).thenAnswer(
            (_) async => const Left(GeneralFailure('Not found')));
        return PodcastDetailBloc(dataSource: mockDataSource);
      },
      act: (bloc) => bloc.add(const FetchPodcastDetailEvent('p1')),
      expect: () => [
        const PodcastDetailLoading(),
        const PodcastDetailError('Not found'),
      ],
    );

    blocTest<PodcastDetailBloc, PodcastDetailState>(
      'adds platform to state on AddPlatform success',
      build: () {
        when(() => mockDataSource.createPlatform('p1', any()))
            .thenAnswer((_) async => Right(testPlatform));
        return PodcastDetailBloc(dataSource: mockDataSource);
      },
      seed: () => PodcastDetailLoaded(
        podcast: testPodcast,
        platforms: const [],
        schedules: const [],
      ),
      act: (bloc) => bloc.add(AddPlatformEvent(
        podcastId: 'p1',
        body: testPlatform.toJsonDto(),
      )),
      expect: () => [
        PodcastDetailLoaded(
          podcast: testPodcast,
          platforms: [testPlatform],
          schedules: const [],
        ),
      ],
    );

    blocTest<PodcastDetailBloc, PodcastDetailState>(
      'removes platform from state on DeletePlatform success',
      build: () {
        when(() => mockDataSource.deletePlatform('pl1'))
            .thenAnswer((_) async => const Right(null));
        return PodcastDetailBloc(dataSource: mockDataSource);
      },
      seed: () => PodcastDetailLoaded(
        podcast: testPodcast,
        platforms: [testPlatform],
        schedules: const [],
      ),
      act: (bloc) => bloc.add(const DeletePlatformEvent('pl1')),
      expect: () => [
        PodcastDetailLoaded(
          podcast: testPodcast,
          platforms: const [],
          schedules: const [],
        ),
      ],
    );

    blocTest<PodcastDetailBloc, PodcastDetailState>(
      'adds schedule to state on AddSchedule success',
      build: () {
        when(() => mockDataSource.createSchedule('p1', any()))
            .thenAnswer((_) async => Right(testSchedule));
        return PodcastDetailBloc(dataSource: mockDataSource);
      },
      seed: () => PodcastDetailLoaded(
        podcast: testPodcast,
        platforms: const [],
        schedules: const [],
      ),
      act: (bloc) => bloc.add(AddScheduleEvent(
        podcastId: 'p1',
        body: testSchedule.toJsonDto(),
      )),
      expect: () => [
        PodcastDetailLoaded(
          podcast: testPodcast,
          platforms: const [],
          schedules: [testSchedule],
        ),
      ],
    );

    blocTest<PodcastDetailBloc, PodcastDetailState>(
      'removes schedule from state on DeleteSchedule success',
      build: () {
        when(() => mockDataSource.deleteSchedule('s1'))
            .thenAnswer((_) async => const Right(null));
        return PodcastDetailBloc(dataSource: mockDataSource);
      },
      seed: () => PodcastDetailLoaded(
        podcast: testPodcast,
        platforms: const [],
        schedules: [testSchedule],
      ),
      act: (bloc) => bloc.add(const DeleteScheduleEvent('s1')),
      expect: () => [
        PodcastDetailLoaded(
          podcast: testPodcast,
          platforms: const [],
          schedules: const [],
        ),
      ],
    );
  });
}
