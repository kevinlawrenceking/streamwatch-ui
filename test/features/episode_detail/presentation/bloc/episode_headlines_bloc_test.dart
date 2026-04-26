import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/features/episode_detail/presentation/bloc/episode_headlines_bloc.dart';
import 'package:streamwatch_frontend/features/podcasts/data/data_sources/podcast_data_source.dart';
import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_headline_candidate.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockPodcastDataSource extends Mock implements IPodcastDataSource {}

PodcastHeadlineCandidateModel _h(String id, {String status = 'pending'}) =>
    PodcastHeadlineCandidateModel(
      id: id,
      episodeId: 'e1',
      status: status,
      createdAt: DateTime.utc(2026, 4, 25),
      updatedAt: DateTime.utc(2026, 4, 25),
    );

void main() {
  late MockPodcastDataSource ds;
  setUp(() {
    ds = MockPodcastDataSource();
  });
  EpisodeHeadlinesBloc build() => EpisodeHeadlinesBloc(dataSource: ds);

  group('load', () {
    blocTest<EpisodeHeadlinesBloc, EpisodeHeadlinesState>(
      'happy',
      build: () {
        when(() => ds.listHeadlineCandidates('e1'))
            .thenAnswer((_) async => Right([_h('a'), _h('b')]));
        return build();
      },
      act: (b) => b.add(const LoadHeadlinesEvent('e1')),
      expect: () => [
        const EpisodeHeadlinesLoading(),
        isA<EpisodeHeadlinesLoaded>()
            .having((s) => s.candidates.length, 'count', 2),
      ],
    );
  });

  group('create + delete', () {
    blocTest<EpisodeHeadlinesBloc, EpisodeHeadlinesState>(
      'create success appends',
      build: () {
        when(() => ds.createHeadlineCandidate('e1', any()))
            .thenAnswer((_) async => Right(_h('new')));
        return build();
      },
      seed: () => EpisodeHeadlinesLoaded(candidates: [_h('a')]),
      act: (b) => b
          .add(const CreateHeadlineEvent(episodeId: 'e1', body: {'text': 'x'})),
      expect: () => [
        isA<EpisodeHeadlinesLoaded>()
            .having((s) => s.isMutating, 'mutating', true),
        isA<EpisodeHeadlinesLoaded>()
            .having((s) => s.candidates.length, 'count', 2),
      ],
    );

    blocTest<EpisodeHeadlinesBloc, EpisodeHeadlinesState>(
      'delete optimistic + commit',
      build: () {
        when(() => ds.deleteHeadlineCandidate('a'))
            .thenAnswer((_) async => const Right(null));
        return build();
      },
      seed: () => EpisodeHeadlinesLoaded(candidates: [_h('a'), _h('b')]),
      act: (b) => b.add(const DeleteHeadlineEvent('a')),
      expect: () => [
        isA<EpisodeHeadlinesLoaded>()
            .having((s) => s.candidates.length, 'optimistic', 1),
        isA<EpisodeHeadlinesLoaded>()
            .having((s) => s.candidates.length, 'committed', 1),
      ],
    );

    blocTest<EpisodeHeadlinesBloc, EpisodeHeadlinesState>(
      'delete rollback restores',
      build: () {
        when(() => ds.deleteHeadlineCandidate('a'))
            .thenAnswer((_) async => const Left(GeneralFailure('boom')));
        return build();
      },
      seed: () => EpisodeHeadlinesLoaded(candidates: [_h('a'), _h('b')]),
      act: (b) => b.add(const DeleteHeadlineEvent('a')),
      expect: () => [
        isA<EpisodeHeadlinesLoaded>(),
        isA<EpisodeHeadlinesLoaded>()
            .having((s) => s.candidates.length, 'restored', 2)
            .having((s) => s.lastActionError, 'error', 'boom'),
      ],
    );
  });

  group('approve (Lock #8 / 503 race path)', () {
    blocTest<EpisodeHeadlinesBloc, EpisodeHeadlinesState>(
      'approve success replaces candidate',
      build: () {
        when(() => ds.approveHeadlineCandidate('a'))
            .thenAnswer((_) async => Right(_h('a', status: 'approved')));
        return build();
      },
      seed: () => EpisodeHeadlinesLoaded(candidates: [_h('a')]),
      act: (b) => b.add(const ApproveHeadlineEvent(candidateId: 'a')),
      expect: () => [
        isA<EpisodeHeadlinesLoaded>()
            .having((s) => s.isMutating, 'mutating', true),
        isA<EpisodeHeadlinesLoaded>()
            .having((s) => s.candidates.first.status, 'approved', 'approved'),
      ],
    );

    blocTest<EpisodeHeadlinesBloc, EpisodeHeadlinesState>(
      'approve 409: specific message + auto-refetch dispatches LoadHeadlines',
      build: () {
        when(() => ds.approveHeadlineCandidate('a')).thenAnswer((_) async =>
            const Left(HttpFailure(statusCode: 409, message: 'not pending')));
        // After 409, the bloc dispatches LoadHeadlinesEvent('e1') so
        // listHeadlineCandidates must also be stubbed.
        when(() => ds.listHeadlineCandidates('e1'))
            .thenAnswer((_) async => Right([_h('a', status: 'approved')]));
        return build();
      },
      seed: () => EpisodeHeadlinesLoaded(candidates: [_h('a')]),
      act: (b) =>
          b.add(const ApproveHeadlineEvent(candidateId: 'a', episodeId: 'e1')),
      expect: () => [
        isA<EpisodeHeadlinesLoaded>()
            .having((s) => s.isMutating, 'mutating', true),
        isA<EpisodeHeadlinesLoaded>().having((s) => s.lastActionError,
            'specific message', 'Already finalized by another user'),
        const EpisodeHeadlinesLoading(),
        isA<EpisodeHeadlinesLoaded>(),
      ],
      verify: (_) {
        verify(() => ds.listHeadlineCandidates('e1')).called(1);
      },
    );

    blocTest<EpisodeHeadlinesBloc, EpisodeHeadlinesState>(
      'approve non-409 failure: surfaces server message + no refetch',
      build: () {
        when(() => ds.approveHeadlineCandidate('a'))
            .thenAnswer((_) async => const Left(GeneralFailure('other')));
        return build();
      },
      seed: () => EpisodeHeadlinesLoaded(candidates: [_h('a')]),
      act: (b) =>
          b.add(const ApproveHeadlineEvent(candidateId: 'a', episodeId: 'e1')),
      expect: () => [
        isA<EpisodeHeadlinesLoaded>(),
        isA<EpisodeHeadlinesLoaded>()
            .having((s) => s.lastActionError, 'message', 'other'),
      ],
      verify: (_) {
        verifyNever(() => ds.listHeadlineCandidates('e1'));
      },
    );
  });

  group('generate (Lock #5 fire-and-forget)', () {
    blocTest<EpisodeHeadlinesBloc, EpisodeHeadlinesState>(
      '202 Accepted: isGenerating stays true',
      build: () {
        when(() => ds.generateHeadlines('e1'))
            .thenAnswer((_) async => const Right(null));
        return build();
      },
      seed: () => EpisodeHeadlinesLoaded(candidates: [_h('a')]),
      act: (b) => b.add(const GenerateHeadlinesEvent('e1')),
      // Lock #5: fire-and-forget. The optimistic emit (isGenerating=true) is
      // the only emission on success -- no follow-up emit since the state
      // does not change (poll-free per Lock #5).
      expect: () => [
        isA<EpisodeHeadlinesLoaded>()
            .having((s) => s.isGenerating, 'isGenerating', true)
            .having((s) => s.lastActionError, 'no error', isNull),
      ],
    );

    blocTest<EpisodeHeadlinesBloc, EpisodeHeadlinesState>(
      'failure clears isGenerating + surfaces error',
      build: () {
        when(() => ds.generateHeadlines('e1')).thenAnswer((_) async =>
            const Left(HttpFailure(
                statusCode: 503, message: 'Headline enqueuer unconfigured')));
        return build();
      },
      seed: () => EpisodeHeadlinesLoaded(candidates: [_h('a')]),
      act: (b) => b.add(const GenerateHeadlinesEvent('e1')),
      expect: () => [
        isA<EpisodeHeadlinesLoaded>()
            .having((s) => s.isGenerating, 'isGenerating', true),
        isA<EpisodeHeadlinesLoaded>()
            .having((s) => s.isGenerating, 'cleared', false)
            .having((s) => s.lastActionError, 'error',
                'Headline enqueuer unconfigured'),
      ],
    );
  });

  blocTest<EpisodeHeadlinesBloc, EpisodeHeadlinesState>(
    'error acknowledged clears lastActionError',
    build: () => build(),
    seed: () =>
        EpisodeHeadlinesLoaded(candidates: [_h('a')], lastActionError: 'old'),
    act: (b) => b.add(const EpisodeHeadlinesErrorAcknowledged()),
    expect: () => [
      isA<EpisodeHeadlinesLoaded>()
          .having((s) => s.lastActionError, 'cleared', isNull),
    ],
  );
}
