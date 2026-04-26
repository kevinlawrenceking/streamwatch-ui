import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/features/episode_detail/presentation/bloc/episode_detail_bloc.dart';
import 'package:streamwatch_frontend/features/podcasts/data/data_sources/podcast_data_source.dart';
import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_episode.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockPodcastDataSource extends Mock implements IPodcastDataSource {}

PodcastEpisodeModel _ep(String id, {String? title}) => PodcastEpisodeModel(
      id: id,
      podcastId: 'p',
      title: title ?? 'Episode $id',
      createdAt: DateTime.utc(2026, 4, 25),
    );

void main() {
  late MockPodcastDataSource ds;

  setUp(() {
    ds = MockPodcastDataSource();
  });

  EpisodeDetailBloc build() => EpisodeDetailBloc(dataSource: ds);

  group('EpisodeDetailBloc — load', () {
    blocTest<EpisodeDetailBloc, EpisodeDetailState>(
      'happy: Loading -> Loaded',
      build: () {
        when(() => ds.getEpisode('e1'))
            .thenAnswer((_) async => Right(_ep('e1')));
        return build();
      },
      act: (b) => b.add(const LoadEpisodeEvent('e1')),
      expect: () => [
        const EpisodeDetailLoading(),
        isA<EpisodeDetailLoaded>()
            .having((s) => s.episode.id, 'id', 'e1')
            .having((s) => s.isMutating, 'isMutating', false)
            .having((s) => s.lastActionError, 'no error', isNull),
      ],
    );

    blocTest<EpisodeDetailBloc, EpisodeDetailState>(
      'failure surfaces Error state',
      build: () {
        when(() => ds.getEpisode('e1'))
            .thenAnswer((_) async => const Left(GeneralFailure('boom')));
        return build();
      },
      act: (b) => b.add(const LoadEpisodeEvent('e1')),
      expect: () => [
        const EpisodeDetailLoading(),
        const EpisodeDetailError('boom'),
      ],
    );
  });

  group('EpisodeDetailBloc — mark reviewed', () {
    blocTest<EpisodeDetailBloc, EpisodeDetailState>(
      'success: emits isMutating=true then committed episode',
      build: () {
        when(() => ds.markEpisodeReviewed('e1'))
            .thenAnswer((_) async => Right(_ep('e1', title: 'New')));
        return build();
      },
      seed: () => EpisodeDetailLoaded(episode: _ep('e1')),
      act: (b) => b.add(const MarkReviewedEvent('e1')),
      expect: () => [
        isA<EpisodeDetailLoaded>()
            .having((s) => s.isMutating, 'isMutating during', true),
        isA<EpisodeDetailLoaded>()
            .having((s) => s.isMutating, 'isMutating after', false)
            .having((s) => s.episode.title, 'committed', 'New'),
      ],
    );

    blocTest<EpisodeDetailBloc, EpisodeDetailState>(
      'rollback: prior episode preserved + error message',
      build: () {
        when(() => ds.markEpisodeReviewed('e1')).thenAnswer((_) async =>
            const Left(HttpFailure(statusCode: 409, message: 'backward')));
        return build();
      },
      seed: () => EpisodeDetailLoaded(episode: _ep('e1', title: 'Prior')),
      act: (b) => b.add(const MarkReviewedEvent('e1')),
      expect: () => [
        isA<EpisodeDetailLoaded>()
            .having((s) => s.isMutating, 'isMutating during', true),
        isA<EpisodeDetailLoaded>()
            .having((s) => s.isMutating, 'isMutating after', false)
            .having((s) => s.episode.title, 'prior preserved', 'Prior')
            .having((s) => s.lastActionError, 'error surfaced', 'backward'),
      ],
    );
  });

  group('EpisodeDetailBloc — request clip', () {
    blocTest<EpisodeDetailBloc, EpisodeDetailState>(
      'success: committed episode',
      build: () {
        when(() => ds.requestEpisodeClip('e1'))
            .thenAnswer((_) async => Right(_ep('e1', title: 'Clipped')));
        return build();
      },
      seed: () => EpisodeDetailLoaded(episode: _ep('e1')),
      act: (b) => b.add(const RequestClipEvent('e1')),
      expect: () => [
        isA<EpisodeDetailLoaded>()
            .having((s) => s.isMutating, 'isMutating during', true),
        isA<EpisodeDetailLoaded>()
            .having((s) => s.isMutating, 'isMutating after', false)
            .having((s) => s.episode.title, 'committed', 'Clipped'),
      ],
    );

    blocTest<EpisodeDetailBloc, EpisodeDetailState>(
      'rollback on Left',
      build: () {
        when(() => ds.requestEpisodeClip('e1'))
            .thenAnswer((_) async => const Left(GeneralFailure('rollback me')));
        return build();
      },
      seed: () => EpisodeDetailLoaded(episode: _ep('e1', title: 'Prior')),
      act: (b) => b.add(const RequestClipEvent('e1')),
      expect: () => [
        isA<EpisodeDetailLoaded>()
            .having((s) => s.isMutating, 'isMutating during', true),
        isA<EpisodeDetailLoaded>()
            .having((s) => s.episode.title, 'prior preserved', 'Prior')
            .having((s) => s.lastActionError, 'error surfaced', 'rollback me'),
      ],
    );
  });

  group('EpisodeDetailBloc — edit metadata', () {
    blocTest<EpisodeDetailBloc, EpisodeDetailState>(
      'success: server-returned episode replaces',
      build: () {
        when(() => ds.updateEpisode('e1', any()))
            .thenAnswer((_) async => Right(_ep('e1', title: 'Server Title')));
        return build();
      },
      seed: () => EpisodeDetailLoaded(episode: _ep('e1', title: 'Local')),
      act: (b) => b.add(EditMetadataEvent(
        episodeId: 'e1',
        body: const {'title': 'Local'},
      )),
      expect: () => [
        isA<EpisodeDetailLoaded>()
            .having((s) => s.isMutating, 'isMutating during', true),
        isA<EpisodeDetailLoaded>()
            .having((s) => s.episode.title, 'server wins', 'Server Title'),
      ],
    );
  });

  group('EpisodeDetailBloc — error acknowledged', () {
    blocTest<EpisodeDetailBloc, EpisodeDetailState>(
      'clears lastActionError',
      build: () => build(),
      seed: () => EpisodeDetailLoaded(
        episode: _ep('e1'),
        lastActionError: 'old',
      ),
      act: (b) => b.add(const EpisodeDetailErrorAcknowledged()),
      expect: () => [
        isA<EpisodeDetailLoaded>()
            .having((s) => s.lastActionError, 'cleared', isNull),
      ],
    );
  });
}
