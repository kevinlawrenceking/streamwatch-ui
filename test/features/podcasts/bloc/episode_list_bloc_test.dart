import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/features/podcasts/data/data_sources/podcast_data_source.dart';
import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_episode.dart';
import 'package:streamwatch_frontend/features/podcasts/presentation/bloc/episode_list_bloc.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockPodcastDataSource extends Mock implements IPodcastDataSource {}

void main() {
  late MockPodcastDataSource mockDataSource;

  final testEpisode = PodcastEpisodeModel(
    id: 'e1',
    podcastId: 'p1',
    title: 'Episode 1',
    source: 'rss',
    publishedAt: DateTime(2026, 1, 15),
    createdAt: DateTime(2026, 1, 15),
  );

  final testResponse = PaginatedResponse<PodcastEpisodeModel>(
    items: [testEpisode],
    total: 1,
    page: 1,
    pageSize: 20,
  );

  setUp(() {
    mockDataSource = MockPodcastDataSource();
  });

  group('EpisodeListBloc', () {
    blocTest<EpisodeListBloc, EpisodeListState>(
      'emits [Loading, Loaded] when FetchEpisodes succeeds',
      build: () {
        when(() => mockDataSource.listEpisodes(
              'p1',
              page: any(named: 'page'),
              pageSize: any(named: 'pageSize'),
            )).thenAnswer((_) async => Right(testResponse));
        return EpisodeListBloc(dataSource: mockDataSource);
      },
      act: (bloc) =>
          bloc.add(const FetchEpisodesEvent(podcastId: 'p1')),
      expect: () => [
        const EpisodeListLoading(),
        EpisodeListLoaded(
          episodes: [testEpisode],
          hasMore: false,
          currentPage: 1,
        ),
      ],
    );

    blocTest<EpisodeListBloc, EpisodeListState>(
      'emits [Loading, Error] when FetchEpisodes fails',
      build: () {
        when(() => mockDataSource.listEpisodes(
              'p1',
              page: any(named: 'page'),
              pageSize: any(named: 'pageSize'),
            )).thenAnswer(
            (_) async => const Left(GeneralFailure('Network error')));
        return EpisodeListBloc(dataSource: mockDataSource);
      },
      act: (bloc) =>
          bloc.add(const FetchEpisodesEvent(podcastId: 'p1')),
      expect: () => [
        const EpisodeListLoading(),
        const EpisodeListError('Network error'),
      ],
    );

    blocTest<EpisodeListBloc, EpisodeListState>(
      'appends episodes on page 2 load',
      build: () {
        final page2Episode = PodcastEpisodeModel(
          id: 'e2',
          podcastId: 'p1',
          title: 'Episode 2',
          createdAt: DateTime(2026, 1, 16),
        );
        when(() => mockDataSource.listEpisodes(
              'p1',
              page: any(named: 'page'),
              pageSize: any(named: 'pageSize'),
            )).thenAnswer((_) async => Right(PaginatedResponse(
              items: [page2Episode],
              total: 2,
              page: 2,
              pageSize: 20,
            )));
        return EpisodeListBloc(dataSource: mockDataSource);
      },
      seed: () => EpisodeListLoaded(
        episodes: [testEpisode],
        hasMore: true,
        currentPage: 1,
      ),
      act: (bloc) => bloc
          .add(const FetchEpisodesEvent(podcastId: 'p1', page: 2)),
      expect: () => [
        isA<EpisodeListLoaded>()
            .having((s) => s.episodes.length, 'episodes length', 2)
            .having((s) => s.currentPage, 'currentPage', 2),
      ],
    );
  });
}
