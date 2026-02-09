import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/sources/collection_data_source.dart';
import 'collections_event.dart';
import 'collections_state.dart';

/// BLoC for managing collections state.
class CollectionsBloc extends Bloc<CollectionsEvent, CollectionsState> {
  final ICollectionDataSource _collectionDataSource;

  CollectionsBloc({required ICollectionDataSource collectionDataSource})
      : _collectionDataSource = collectionDataSource,
        super(const CollectionsInitial()) {
    on<LoadCollectionsEvent>(_onLoadCollections);
    on<CreateCollectionEvent>(_onCreateCollection);
    on<MakeDefaultEvent>(_onMakeDefault);
    on<SelectCollectionEvent>(_onSelectCollection);
  }

  Future<void> _onLoadCollections(
    LoadCollectionsEvent event,
    Emitter<CollectionsState> emit,
  ) async {
    emit(const CollectionsLoading());

    final result = await _collectionDataSource.getCollections();

    result.fold(
      (failure) => emit(CollectionsError(failure)),
      (collections) => emit(CollectionsLoaded(collections: collections)),
    );
  }

  Future<void> _onCreateCollection(
    CreateCollectionEvent event,
    Emitter<CollectionsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CollectionsLoaded) return;

    final result = await _collectionDataSource.createCollection(
      name: event.name,
      visibility: event.visibility,
      tags: event.tags,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(
        actionError: failure.message,
      )),
      (collection) {
        final updated = [...currentState.collections, collection];
        emit(currentState.copyWith(
          collections: updated,
          actionSuccess: 'Collection "${collection.name}" created',
        ));
      },
    );
  }

  Future<void> _onMakeDefault(
    MakeDefaultEvent event,
    Emitter<CollectionsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CollectionsLoaded) return;

    final result = await _collectionDataSource.makeDefault(event.collectionId);

    result.fold(
      (failure) => emit(currentState.copyWith(
        actionError: failure.message,
      )),
      (_) {
        // Reload collections to reflect the change
        add(const LoadCollectionsEvent());
      },
    );
  }

  void _onSelectCollection(
    SelectCollectionEvent event,
    Emitter<CollectionsState> emit,
  ) {
    final currentState = state;
    if (currentState is! CollectionsLoaded) return;

    if (event.collectionId == null) {
      emit(currentState.copyWith(clearSelectedCollection: true));
    } else {
      emit(currentState.copyWith(selectedCollectionId: event.collectionId));
    }
  }
}
