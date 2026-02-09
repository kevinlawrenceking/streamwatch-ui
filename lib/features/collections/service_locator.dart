import 'package:get_it/get_it.dart';
import '../../data/sources/collection_data_source.dart';
import 'bloc/collections_bloc.dart';

/// Service locator for the collections feature.
class ServiceLocator {
  static bool _initialized = false;

  /// Initializes feature dependencies.
  /// Must be called after global service locator is initialized.
  static void init() {
    if (_initialized) {
      throw Exception('Collections ServiceLocator already initialized!');
    }

    final sl = GetIt.instance;

    // CollectionsBloc - factory (new instance each time)
    sl.registerFactory<CollectionsBloc>(
      () => CollectionsBloc(
          collectionDataSource: sl<ICollectionDataSource>()),
    );

    _initialized = true;
  }
}
