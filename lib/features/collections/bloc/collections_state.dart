import 'package:equatable/equatable.dart';
import '../../../data/models/collection_model.dart';
import '../../../shared/errors/failures/failure.dart';

/// States for the collections BLoC.
abstract class CollectionsState extends Equatable {
  const CollectionsState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded.
class CollectionsInitial extends CollectionsState {
  const CollectionsInitial();
}

/// Loading state while fetching collections.
class CollectionsLoading extends CollectionsState {
  const CollectionsLoading();
}

/// Collections loaded successfully.
class CollectionsLoaded extends CollectionsState {
  final List<CollectionModel> collections;
  final String? selectedCollectionId;
  final String? actionError;
  final String? actionSuccess;

  const CollectionsLoaded({
    required this.collections,
    this.selectedCollectionId,
    this.actionError,
    this.actionSuccess,
  });

  @override
  List<Object?> get props => [
        collections,
        selectedCollectionId,
        actionError,
        actionSuccess,
      ];

  CollectionsLoaded copyWith({
    List<CollectionModel>? collections,
    String? selectedCollectionId,
    String? actionError,
    String? actionSuccess,
    bool clearSelectedCollection = false,
    bool clearActionError = false,
    bool clearActionSuccess = false,
  }) {
    return CollectionsLoaded(
      collections: collections ?? this.collections,
      selectedCollectionId: clearSelectedCollection
          ? null
          : (selectedCollectionId ?? this.selectedCollectionId),
      actionError:
          clearActionError ? null : (actionError ?? this.actionError),
      actionSuccess:
          clearActionSuccess ? null : (actionSuccess ?? this.actionSuccess),
    );
  }

  /// Get the default collection, if any.
  CollectionModel? get defaultCollection =>
      collections.where((c) => c.isDefault).firstOrNull;

  /// Get the currently selected collection, if any.
  CollectionModel? get selectedCollection => selectedCollectionId == null
      ? null
      : collections
          .where((c) => c.id == selectedCollectionId)
          .firstOrNull;
}

/// Error state.
class CollectionsError extends CollectionsState {
  final Failure failure;

  const CollectionsError(this.failure);

  @override
  List<Object?> get props => [failure];
}
