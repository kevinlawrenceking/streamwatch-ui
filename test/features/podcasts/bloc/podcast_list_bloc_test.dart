import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/features/podcasts/data/data_sources/podcast_data_source.dart';
import 'package:streamwatch_frontend/features/podcasts/data/models/podcast.dart';
import 'package:streamwatch_frontend/features/podcasts/presentation/bloc/podcast_list_bloc.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockPodcastDataSource extends Mock implements IPodcastDataSource {}

void main() {
  late MockPodcastDataSource mockDataSource;

  final testPodcast = PodcastModel(
    id: 'p1',
    name: 'Test Podcast',
    description: 'A test podcast',
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
  );

  final testResponse = PaginatedResponse<PodcastModel>(
    items: [testPodcast],
    total: 1,
    page: 1,
    pageSize: 20,
  );

  setUp(() {
    mockDataSource = MockPodcastDataSource();
  });

  group('PodcastListBloc', () {
    blocTest<PodcastListBloc, PodcastListState>(
      'emits [Loading, Loaded] when FetchPodcasts succeeds',
      build: () {
        when(() => mockDataSource.listPodcasts(
              page: any(named: 'page'),
              pageSize: any(named: 'pageSize'),
              includeInactive: any(named: 'includeInactive'),
            )).thenAnswer((_) async => Right(testResponse));
        return PodcastListBloc(dataSource: mockDataSource);
      },
      act: (bloc) => bloc.add(const FetchPodcastsEvent()),
      expect: () => [
        const PodcastListLoading(),
        PodcastListLoaded(
          podcasts: [testPodcast],
          hasMore: false,
          currentPage: 1,
        ),
      ],
    );

    blocTest<PodcastListBloc, PodcastListState>(
      'emits [Loading, Error] when FetchPodcasts fails',
      build: () {
        when(() => mockDataSource.listPodcasts(
              page: any(named: 'page'),
              pageSize: any(named: 'pageSize'),
              includeInactive: any(named: 'includeInactive'),
            )).thenAnswer(
            (_) async => const Left(GeneralFailure('Server error')));
        return PodcastListBloc(dataSource: mockDataSource);
      },
      act: (bloc) => bloc.add(const FetchPodcastsEvent()),
      expect: () => [
        const PodcastListLoading(),
        const PodcastListError('Server error'),
      ],
    );

    blocTest<PodcastListBloc, PodcastListState>(
      'reloads list after CreatePodcast succeeds',
      build: () {
        when(() => mockDataSource.createPodcast(any()))
            .thenAnswer((_) async => Right(testPodcast));
        when(() => mockDataSource.listPodcasts(
              page: any(named: 'page'),
              pageSize: any(named: 'pageSize'),
              includeInactive: any(named: 'includeInactive'),
            )).thenAnswer((_) async => Right(testResponse));
        return PodcastListBloc(dataSource: mockDataSource);
      },
      act: (bloc) =>
          bloc.add(const CreatePodcastEvent({'name': 'New Podcast'})),
      verify: (_) {
        verify(() => mockDataSource.createPodcast(any())).called(1);
        verify(() => mockDataSource.listPodcasts(
              page: any(named: 'page'),
              pageSize: any(named: 'pageSize'),
              includeInactive: any(named: 'includeInactive'),
            )).called(1);
      },
    );

    blocTest<PodcastListBloc, PodcastListState>(
      'reloads list after DeactivatePodcast succeeds',
      build: () {
        when(() => mockDataSource.deactivatePodcast(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockDataSource.listPodcasts(
              page: any(named: 'page'),
              pageSize: any(named: 'pageSize'),
              includeInactive: any(named: 'includeInactive'),
            )).thenAnswer((_) async => Right(testResponse));
        return PodcastListBloc(dataSource: mockDataSource);
      },
      act: (bloc) => bloc.add(const DeactivatePodcastEvent('p1')),
      verify: (_) {
        verify(() => mockDataSource.deactivatePodcast('p1')).called(1);
      },
    );

    blocTest<PodcastListBloc, PodcastListState>(
      'reloads list after ActivatePodcast succeeds',
      build: () {
        when(() => mockDataSource.activatePodcast(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockDataSource.listPodcasts(
              page: any(named: 'page'),
              pageSize: any(named: 'pageSize'),
              includeInactive: any(named: 'includeInactive'),
            )).thenAnswer((_) async => Right(testResponse));
        return PodcastListBloc(dataSource: mockDataSource);
      },
      act: (bloc) => bloc.add(const ActivatePodcastEvent('p1')),
      verify: (_) {
        verify(() => mockDataSource.activatePodcast('p1')).called(1);
      },
    );
  });
}
