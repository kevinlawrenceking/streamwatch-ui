import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:streamwatch_frontend/data/models/collection_model.dart';
import 'package:streamwatch_frontend/data/sources/collection_data_source.dart';
import 'package:streamwatch_frontend/features/collections/bloc/collections_bloc.dart';
import 'package:streamwatch_frontend/features/collections/bloc/collections_event.dart';
import 'package:streamwatch_frontend/features/collections/bloc/collections_state.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockCollectionDataSource extends Mock implements ICollectionDataSource {}

void main() {
  late MockCollectionDataSource mockDS;
  late CollectionModel testCollection;
  late CollectionModel defaultCollection;

  setUp(() {
    mockDS = MockCollectionDataSource();

    testCollection = CollectionModel(
      id: 'coll-1',
      ownerUserId: 'user-1',
      name: 'My Collection',
      visibility: 'private',
      status: 'active',
      isDefault: false,
      videoCount: 5,
      tags: [],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    defaultCollection = CollectionModel(
      id: 'coll-2',
      ownerUserId: 'user-1',
      name: 'Default',
      visibility: 'private',
      status: 'active',
      isDefault: true,
      videoCount: 10,
      tags: [],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  });

  group('UpdateCollectionEvent', () {
    blocTest<CollectionsBloc, CollectionsState>(
      'rename emits updated collection and success message',
      build: () {
        final renamed = CollectionModel(
          id: 'coll-1',
          ownerUserId: 'user-1',
          name: 'Renamed',
          visibility: 'private',
          status: 'active',
          isDefault: false,
          videoCount: 5,
          tags: [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 2),
        );
        when(() => mockDS.updateCollection('coll-1', name: 'Renamed'))
            .thenAnswer((_) async => Right(renamed));
        return CollectionsBloc(collectionDataSource: mockDS);
      },
      seed: () => CollectionsLoaded(
        collections: [testCollection, defaultCollection],
      ),
      act: (bloc) => bloc.add(const UpdateCollectionEvent(
        collectionId: 'coll-1',
        name: 'Renamed',
      )),
      expect: () => [
        isA<CollectionsLoaded>()
            .having(
              (s) => s.collections.firstWhere((c) => c.id == 'coll-1').name,
              'renamed name',
              'Renamed',
            )
            .having(
              (s) => s.actionSuccess,
              'success message',
              contains('updated'),
            ),
      ],
    );

    blocTest<CollectionsBloc, CollectionsState>(
      'archive emits archived collection and success message',
      build: () {
        final archived = CollectionModel(
          id: 'coll-1',
          ownerUserId: 'user-1',
          name: 'My Collection',
          visibility: 'private',
          status: 'archived',
          isDefault: false,
          videoCount: 5,
          tags: [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 2),
        );
        when(() => mockDS.updateCollection('coll-1', status: 'archived'))
            .thenAnswer((_) async => Right(archived));
        return CollectionsBloc(collectionDataSource: mockDS);
      },
      seed: () => CollectionsLoaded(
        collections: [testCollection, defaultCollection],
      ),
      act: (bloc) => bloc.add(const UpdateCollectionEvent(
        collectionId: 'coll-1',
        status: 'archived',
      )),
      expect: () => [
        isA<CollectionsLoaded>()
            .having(
              (s) => s.collections.firstWhere((c) => c.id == 'coll-1').status,
              'archived status',
              'archived',
            )
            .having(
              (s) => s.actionSuccess,
              'success message',
              contains('archived'),
            ),
      ],
    );

    blocTest<CollectionsBloc, CollectionsState>(
      'visibility change emits updated visibility',
      build: () {
        final toggled = CollectionModel(
          id: 'coll-1',
          ownerUserId: 'user-1',
          name: 'My Collection',
          visibility: 'public',
          status: 'active',
          isDefault: false,
          videoCount: 5,
          tags: [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 2),
        );
        when(() => mockDS.updateCollection('coll-1', visibility: 'public'))
            .thenAnswer((_) async => Right(toggled));
        return CollectionsBloc(collectionDataSource: mockDS);
      },
      seed: () => CollectionsLoaded(
        collections: [testCollection, defaultCollection],
      ),
      act: (bloc) => bloc.add(const UpdateCollectionEvent(
        collectionId: 'coll-1',
        visibility: 'public',
      )),
      expect: () => [
        isA<CollectionsLoaded>()
            .having(
              (s) =>
                  s.collections.firstWhere((c) => c.id == 'coll-1').visibility,
              'new visibility',
              'public',
            )
            .having(
              (s) => s.actionSuccess,
              'success message',
              contains('updated'),
            ),
      ],
    );

    blocTest<CollectionsBloc, CollectionsState>(
      'update failure emits actionError',
      build: () {
        when(() => mockDS.updateCollection('coll-1', name: 'Bad'))
            .thenAnswer((_) async => const Left(GeneralFailure('Server error')));
        return CollectionsBloc(collectionDataSource: mockDS);
      },
      seed: () => CollectionsLoaded(
        collections: [testCollection, defaultCollection],
      ),
      act: (bloc) => bloc.add(const UpdateCollectionEvent(
        collectionId: 'coll-1',
        name: 'Bad',
      )),
      expect: () => [
        isA<CollectionsLoaded>().having(
          (s) => s.actionError,
          'error message',
          'Server error',
        ),
      ],
    );
  });

  group('MakeDefaultEvent', () {
    blocTest<CollectionsBloc, CollectionsState>(
      'make default calls data source and reloads',
      build: () {
        when(() => mockDS.makeDefault('coll-1'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockDS.getCollections())
            .thenAnswer((_) async => Right([testCollection, defaultCollection]));
        return CollectionsBloc(collectionDataSource: mockDS);
      },
      seed: () => CollectionsLoaded(
        collections: [testCollection, defaultCollection],
      ),
      act: (bloc) => bloc.add(const MakeDefaultEvent('coll-1')),
      expect: () => [
        // Reload triggers loading then loaded
        isA<CollectionsLoading>(),
        isA<CollectionsLoaded>(),
      ],
      verify: (_) {
        verify(() => mockDS.makeDefault('coll-1')).called(1);
        verify(() => mockDS.getCollections()).called(1);
      },
    );
  });
}
