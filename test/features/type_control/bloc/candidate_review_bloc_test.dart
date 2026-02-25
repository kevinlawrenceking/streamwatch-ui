import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:streamwatch_frontend/data/models/video_type_model.dart';
import 'package:streamwatch_frontend/data/sources/video_type_data_source.dart';
import 'package:streamwatch_frontend/features/type_control/bloc/candidate_review_bloc.dart';
import 'package:streamwatch_frontend/features/type_control/bloc/candidate_review_event.dart';
import 'package:streamwatch_frontend/features/type_control/bloc/candidate_review_state.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockVideoTypeDataSource extends Mock implements IVideoTypeDataSource {}

void main() {
  late MockVideoTypeDataSource mockDataSource;
  late CandidateReviewBloc bloc;

  final tCandidate = VideoTypeRuleCandidateModel(
    id: 'cand-1',
    videoTypeId: 'type-1',
    candidateText: 'Test candidate',
    status: 'pending',
    source: 'llm',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    mockDataSource = MockVideoTypeDataSource();
    bloc = CandidateReviewBloc(dataSource: mockDataSource);
  });

  tearDown(() {
    bloc.close();
  });

  group('CandidateReviewBloc', () {
    test('initial state is CandidateReviewInitial', () {
      expect(bloc.state, const CandidateReviewInitial());
    });

    blocTest<CandidateReviewBloc, CandidateReviewState>(
      'emits [Loading, Loaded] when LoadCandidatesEvent succeeds',
      build: () {
        when(() => mockDataSource.getCandidates(any()))
            .thenAnswer((_) async => Right([tCandidate]));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadCandidatesEvent('type-1')),
      expect: () => [
        const CandidateReviewLoading(),
        CandidateReviewLoaded(candidates: [tCandidate]),
      ],
    );

    blocTest<CandidateReviewBloc, CandidateReviewState>(
      'emits [Loading, Error] when LoadCandidatesEvent fails',
      build: () {
        when(() => mockDataSource.getCandidates(any()))
            .thenAnswer((_) async => const Left(Failure('fail')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadCandidatesEvent('type-1')),
      expect: () => [
        const CandidateReviewLoading(),
        const CandidateReviewError(Failure('fail')),
      ],
    );

    blocTest<CandidateReviewBloc, CandidateReviewState>(
      'emits [Loaded] and reloads when ApproveCandidateEvent succeeds',
      build: () {
        when(() => mockDataSource.approveCandidate(any(), any()))
            .thenAnswer((_) async => Right(tCandidate));
        when(() => mockDataSource.getCandidates(any()))
            .thenAnswer((_) async => Right([tCandidate]));
        return bloc;
      },
      seed: () => CandidateReviewLoaded(candidates: [tCandidate]),
      act: (bloc) => bloc.add(const ApproveCandidateEvent(
        candidateId: 'cand-1',
        videoTypeId: 'type-1',
      )),
      expect: () => [
        CandidateReviewLoaded(candidates: [tCandidate], isSubmitting: true),
        const CandidateReviewLoading(),
        CandidateReviewLoaded(candidates: [tCandidate]),
      ],
    );

    blocTest<CandidateReviewBloc, CandidateReviewState>(
      'emits [Error] when RejectCandidateEvent fails',
      build: () {
        when(() => mockDataSource.rejectCandidate(any(), any()))
            .thenAnswer((_) async => const Left(Failure('fail')));
        return bloc;
      },
      seed: () => CandidateReviewLoaded(candidates: [tCandidate]),
      act: (bloc) => bloc.add(const RejectCandidateEvent(
        candidateId: 'cand-1',
        videoTypeId: 'type-1',
        reason: 'Not relevant',
      )),
      expect: () => [
        CandidateReviewLoaded(candidates: [tCandidate], isSubmitting: true),
        const CandidateReviewError(Failure('fail')),
      ],
    );

    blocTest<CandidateReviewBloc, CandidateReviewState>(
      'emits [Loaded] and reloads when MergeCandidateEvent succeeds',
      build: () {
        when(() => mockDataSource.mergeCandidate(any(), any()))
            .thenAnswer((_) async => Right(tCandidate));
        when(() => mockDataSource.getCandidates(any()))
            .thenAnswer((_) async => Right([tCandidate]));
        return bloc;
      },
      seed: () => CandidateReviewLoaded(candidates: [tCandidate]),
      act: (bloc) => bloc.add(const MergeCandidateEvent(
        candidateId: 'cand-1',
        videoTypeId: 'type-1',
        targetRuleId: 'rule-1',
      )),
      expect: () => [
        CandidateReviewLoaded(candidates: [tCandidate], isSubmitting: true),
        const CandidateReviewLoading(),
        CandidateReviewLoaded(candidates: [tCandidate]),
      ],
    );

    blocTest<CandidateReviewBloc, CandidateReviewState>(
      'emits [Loading, Loaded(empty)] when no candidates exist',
      build: () {
        when(() => mockDataSource.getCandidates(any()))
            .thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadCandidatesEvent('type-1')),
      expect: () => [
        const CandidateReviewLoading(),
        const CandidateReviewLoaded(candidates: []),
      ],
    );
  });
}
