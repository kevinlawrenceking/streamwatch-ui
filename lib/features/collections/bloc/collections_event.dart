import 'package:equatable/equatable.dart';

/// Events for the collections BLoC.
abstract class CollectionsEvent extends Equatable {
  const CollectionsEvent();

  @override
  List<Object?> get props => [];
}

/// Load all collections for the current user.
class LoadCollectionsEvent extends CollectionsEvent {
  const LoadCollectionsEvent();
}

/// Create a new collection.
class CreateCollectionEvent extends CollectionsEvent {
  final String name;
  final String? visibility;
  final List<String>? tags;

  const CreateCollectionEvent({
    required this.name,
    this.visibility,
    this.tags,
  });

  @override
  List<Object?> get props => [name, visibility, tags];
}

/// Set a collection as the user's default.
class MakeDefaultEvent extends CollectionsEvent {
  final String collectionId;

  const MakeDefaultEvent(this.collectionId);

  @override
  List<Object?> get props => [collectionId];
}

/// Select a collection to filter the home view.
class SelectCollectionEvent extends CollectionsEvent {
  final String? collectionId;

  const SelectCollectionEvent(this.collectionId);

  @override
  List<Object?> get props => [collectionId];
}
