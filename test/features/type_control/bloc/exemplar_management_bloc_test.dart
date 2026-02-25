import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:streamwatch_frontend/data/models/video_type_model.dart';
import 'package:streamwatch_frontend/data/sources/video_type_data_source.dart';
import 'package:streamwatch_frontend/features/type_control/bloc/exemplar_management_bloc.dart';
import 'package:streamwatch_frontend/features/type_control/bloc/exemplar_management_event.dart';
import 'package:streamwatch_frontend/features/type_control/bloc/exemplar_management_state.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockVideoTypeDataSource extends Mock implements IVideoTypeDataSource {}

void main() {
  late MockVideoTypeDataSource mockDataSource;
  late ExemplarManagementBloc bloc;

  final tExemplar = VideoTypeExemplarModel(
    id: 'ex-1',
    videoTypeId: 'type-1',
    clipId: 'CLIP001',
    exemplarKind: 'canonical',
    notes: 'Test exemplar',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    mockDataSource = MockVideoTypeDataSource();
    bloc = ExemplarManagementBloc(dataSource: mockDataSource);
  });

  tearDown(() {
    bloc.close();
  });

  group('ExemplarManagementBloc', () {
    test('initial state is ExemplarManagementInitial', () {
      expect(bloc.state, const ExemplarManagementInitial());
    });

    blocTest<ExemplarManagementBloc, ExemplarManagementState>(
      'emits [Loading, Loaded] when LoadExemplarsEvent succeeds',
      build: () {
        when(() => mockDataSource.getExemplars(any()))
            .thenAnswer((_) async => Right([tExemplar]));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadExemplarsEvent('type-1')),
      expect: () => [
        const ExemplarManagementLoading(),
        ExemplarManagementLoaded(exemplars: [tExemplar]),
      ],
    );

    blocTest<ExemplarManagementBloc, ExemplarManagementState>(
      'emits [Loading, Error] when LoadExemplarsEvent fails',
      build: () {
        when(() => mockDataSource.getExemplars(any()))
            .thenAnswer((_) async => const Left(Failure('fail')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadExemplarsEvent('type-1')),
      expect: () => [
        const ExemplarManagementLoading(),
        const ExemplarManagementError(Failure('fail')),
      ],
    );

    blocTest<ExemplarManagementBloc, ExemplarManagementState>(
      'emits [Loaded(submitting)] and reloads when BulkCreateExemplarsEvent succeeds',
      build: () {
        when(() => mockDataSource.bulkCreateExemplars(any(), any()))
            .thenAnswer((_) async => Right([tExemplar]));
        when(() => mockDataSource.getExemplars(any()))
            .thenAnswer((_) async => Right([tExemplar]));
        return bloc;
      },
      seed: () => ExemplarManagementLoaded(exemplars: [tExemplar]),
      act: (bloc) => bloc.add(const BulkCreateExemplarsEvent(
        videoTypeId: 'type-1',
        clipIds: ['CLIP001', 'CLIP002'],
        exemplarKind: 'canonical',
      )),
      expect: () => [
        ExemplarManagementLoaded(exemplars: [tExemplar], isSubmitting: true),
        const ExemplarManagementLoading(),
        ExemplarManagementLoaded(exemplars: [tExemplar]),
      ],
    );

    blocTest<ExemplarManagementBloc, ExemplarManagementState>(
      'emits [Error] when BulkCreateExemplarsEvent fails',
      build: () {
        when(() => mockDataSource.bulkCreateExemplars(any(), any()))
            .thenAnswer((_) async => const Left(Failure('fail')));
        return bloc;
      },
      seed: () => ExemplarManagementLoaded(exemplars: [tExemplar]),
      act: (bloc) => bloc.add(const BulkCreateExemplarsEvent(
        videoTypeId: 'type-1',
        clipIds: ['CLIP001'],
      )),
      expect: () => [
        ExemplarManagementLoaded(exemplars: [tExemplar], isSubmitting: true),
        const ExemplarManagementError(Failure('fail')),
      ],
    );

    blocTest<ExemplarManagementBloc, ExemplarManagementState>(
      'emits [Loaded(submitting)] and reloads when DeleteExemplarEvent succeeds',
      build: () {
        when(() => mockDataSource.deleteExemplar(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockDataSource.getExemplars(any()))
            .thenAnswer((_) async => const Right([]));
        return bloc;
      },
      seed: () => ExemplarManagementLoaded(exemplars: [tExemplar]),
      act: (bloc) => bloc.add(const DeleteExemplarEvent(
        exemplarId: 'ex-1',
        videoTypeId: 'type-1',
      )),
      expect: () => [
        ExemplarManagementLoaded(exemplars: [tExemplar], isSubmitting: true),
        const ExemplarManagementLoading(),
        const ExemplarManagementLoaded(exemplars: []),
      ],
    );

    blocTest<ExemplarManagementBloc, ExemplarManagementState>(
      'emits [Error] when DeleteExemplarEvent fails',
      build: () {
        when(() => mockDataSource.deleteExemplar(any()))
            .thenAnswer((_) async => const Left(Failure('fail')));
        return bloc;
      },
      seed: () => ExemplarManagementLoaded(exemplars: [tExemplar]),
      act: (bloc) => bloc.add(const DeleteExemplarEvent(
        exemplarId: 'ex-1',
        videoTypeId: 'type-1',
      )),
      expect: () => [
        ExemplarManagementLoaded(exemplars: [tExemplar], isSubmitting: true),
        const ExemplarManagementError(Failure('fail')),
      ],
    );
  });
}
