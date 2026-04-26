import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/features/episode_detail/presentation/bloc/episode_transcripts_bloc.dart';
import 'package:streamwatch_frontend/features/podcasts/data/data_sources/podcast_data_source.dart';
import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_transcript.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockPodcastDataSource extends Mock implements IPodcastDataSource {}

PodcastTranscriptModel _t(String id, {bool primary = false}) =>
    PodcastTranscriptModel(
      id: id,
      episodeId: 'e1',
      variant: 'raw',
      sourceType: 'auto',
      isPrimary: primary,
      createdAt: DateTime.utc(2026, 4, 25),
      updatedAt: DateTime.utc(2026, 4, 25),
    );

void main() {
  late MockPodcastDataSource ds;
  setUp(() {
    ds = MockPodcastDataSource();
  });
  EpisodeTranscriptsBloc build() => EpisodeTranscriptsBloc(dataSource: ds);

  group('load', () {
    blocTest<EpisodeTranscriptsBloc, EpisodeTranscriptsState>(
      'happy',
      build: () {
        when(() => ds.listTranscripts('e1'))
            .thenAnswer((_) async => Right([_t('a'), _t('b')]));
        return build();
      },
      act: (b) => b.add(const LoadTranscriptsEvent('e1')),
      expect: () => [
        const EpisodeTranscriptsLoading(),
        isA<EpisodeTranscriptsLoaded>()
            .having((s) => s.transcripts.length, 'count', 2),
      ],
    );

    blocTest<EpisodeTranscriptsBloc, EpisodeTranscriptsState>(
      'error',
      build: () {
        when(() => ds.listTranscripts('e1'))
            .thenAnswer((_) async => const Left(GeneralFailure('x')));
        return build();
      },
      act: (b) => b.add(const LoadTranscriptsEvent('e1')),
      expect: () => [
        const EpisodeTranscriptsLoading(),
        const EpisodeTranscriptsError('x'),
      ],
    );
  });

  group('create', () {
    blocTest<EpisodeTranscriptsBloc, EpisodeTranscriptsState>(
      'success appends server-returned transcript',
      build: () {
        when(() => ds.createTranscript('e1', any()))
            .thenAnswer((_) async => Right(_t('new')));
        return build();
      },
      seed: () => EpisodeTranscriptsLoaded(transcripts: [_t('a')]),
      act: (b) => b.add(const CreateTranscriptEvent(
        episodeId: 'e1',
        body: {'variant': 'raw', 'source_type': 'auto'},
      )),
      expect: () => [
        isA<EpisodeTranscriptsLoaded>()
            .having((s) => s.isMutating, 'mutating', true),
        isA<EpisodeTranscriptsLoaded>()
            .having((s) => s.transcripts.length, 'count', 2)
            .having((s) => s.transcripts.last.id, 'last id', 'new'),
      ],
    );

    blocTest<EpisodeTranscriptsBloc, EpisodeTranscriptsState>(
      'rollback on failure',
      build: () {
        when(() => ds.createTranscript('e1', any())).thenAnswer(
            (_) async => const Left(GeneralFailure('create failed')));
        return build();
      },
      seed: () => EpisodeTranscriptsLoaded(transcripts: [_t('a')]),
      act: (b) => b.add(const CreateTranscriptEvent(
        episodeId: 'e1',
        body: {'variant': 'raw', 'source_type': 'auto'},
      )),
      expect: () => [
        isA<EpisodeTranscriptsLoaded>()
            .having((s) => s.isMutating, 'mutating', true),
        isA<EpisodeTranscriptsLoaded>()
            .having((s) => s.transcripts.length, 'unchanged', 1)
            .having(
                (s) => s.lastActionError, 'error surfaced', 'create failed'),
      ],
    );
  });

  group('delete', () {
    blocTest<EpisodeTranscriptsBloc, EpisodeTranscriptsState>(
      'success: optimistic remove sticks',
      build: () {
        when(() => ds.deleteTranscript('a'))
            .thenAnswer((_) async => const Right(null));
        return build();
      },
      seed: () => EpisodeTranscriptsLoaded(transcripts: [_t('a'), _t('b')]),
      act: (b) => b.add(const DeleteTranscriptEvent('a')),
      expect: () => [
        isA<EpisodeTranscriptsLoaded>()
            .having((s) => s.transcripts.length, 'optimistic', 1)
            .having((s) => s.isMutating, 'mutating', true),
        isA<EpisodeTranscriptsLoaded>()
            .having((s) => s.transcripts.length, 'committed', 1)
            .having((s) => s.isMutating, 'mutating done', false),
      ],
    );

    blocTest<EpisodeTranscriptsBloc, EpisodeTranscriptsState>(
      'rollback re-inserts on failure',
      build: () {
        when(() => ds.deleteTranscript('a')).thenAnswer(
            (_) async => const Left(GeneralFailure('delete failed')));
        return build();
      },
      seed: () => EpisodeTranscriptsLoaded(transcripts: [_t('a'), _t('b')]),
      act: (b) => b.add(const DeleteTranscriptEvent('a')),
      expect: () => [
        isA<EpisodeTranscriptsLoaded>()
            .having((s) => s.transcripts.length, 'optimistic', 1),
        isA<EpisodeTranscriptsLoaded>()
            .having((s) => s.transcripts.length, 'restored', 2)
            .having(
                (s) => s.lastActionError, 'error surfaced', 'delete failed'),
      ],
    );
  });

  group('set primary', () {
    blocTest<EpisodeTranscriptsBloc, EpisodeTranscriptsState>(
      'success: only target is primary',
      build: () {
        when(() => ds.setPrimaryTranscript('b'))
            .thenAnswer((_) async => Right(_t('b', primary: true)));
        return build();
      },
      seed: () => EpisodeTranscriptsLoaded(
          transcripts: [_t('a', primary: true), _t('b')]),
      act: (b) => b.add(const SetPrimaryTranscriptEvent('b')),
      expect: () => [
        isA<EpisodeTranscriptsLoaded>()
            .having((s) => s.isMutating, 'mutating', true),
        isA<EpisodeTranscriptsLoaded>()
            .having((s) => s.transcripts.where((t) => t.isPrimary).length,
                'one primary', 1)
            .having(
                (s) => s.transcripts.firstWhere((t) => t.id == 'b').isPrimary,
                'target primary',
                true),
      ],
    );

    blocTest<EpisodeTranscriptsBloc, EpisodeTranscriptsState>(
      'rollback restores prior primary',
      build: () {
        when(() => ds.setPrimaryTranscript('b'))
            .thenAnswer((_) async => const Left(GeneralFailure('fail')));
        return build();
      },
      seed: () => EpisodeTranscriptsLoaded(
          transcripts: [_t('a', primary: true), _t('b')]),
      act: (b) => b.add(const SetPrimaryTranscriptEvent('b')),
      expect: () => [
        isA<EpisodeTranscriptsLoaded>(),
        isA<EpisodeTranscriptsLoaded>().having(
            (s) => s.transcripts.firstWhere((t) => t.id == 'a').isPrimary,
            'restored prior primary',
            true),
      ],
    );
  });

  blocTest<EpisodeTranscriptsBloc, EpisodeTranscriptsState>(
    'error acknowledged clears lastActionError',
    build: () => build(),
    seed: () => EpisodeTranscriptsLoaded(
        transcripts: [_t('a')], lastActionError: 'old'),
    act: (b) => b.add(const EpisodeTranscriptsErrorAcknowledged()),
    expect: () => [
      isA<EpisodeTranscriptsLoaded>()
          .having((s) => s.lastActionError, 'cleared', isNull),
    ],
  );
}
