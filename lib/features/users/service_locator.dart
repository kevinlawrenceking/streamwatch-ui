import 'package:get_it/get_it.dart';

import '../../data/sources/user_data_source.dart';
import 'bloc/users_bloc.dart';

/// Service locator for the users feature.
class ServiceLocator {
  static bool _initialized = false;

  /// Initializes feature dependencies.
  /// Must be called after global service locator is initialized.
  static void init() {
    if (_initialized) {
      throw Exception('Users ServiceLocator already initialized!');
    }

    final sl = GetIt.instance;

    // UsersBloc - factory (new instance each time)
    sl.registerFactory<UsersBloc>(
      () => UsersBloc(userDataSource: sl<IUserDataSource>()),
    );

    _initialized = true;
  }
}
