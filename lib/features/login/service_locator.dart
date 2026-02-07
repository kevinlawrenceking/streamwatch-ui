import 'package:get_it/get_it.dart';

import '../../data/sources/auth_data_source.dart';
import '../../shared/bloc/auth_session_bloc.dart';
import 'bloc/login_bloc.dart';

/// Service locator for the login feature.
class ServiceLocator {
  static bool _initialized = false;

  /// Initializes feature dependencies.
  /// Must be called after global service locator is initialized.
  static void init() {
    if (_initialized) {
      throw Exception('Login ServiceLocator already initialized!');
    }

    final sl = GetIt.instance;

    // LoginBloc - factory (new instance each time)
    sl.registerFactory<LoginBloc>(
      () => LoginBloc(
        authDataSource: sl<IAuthDataSource>(),
        authSessionBloc: sl<AuthSessionBloc>(),
      ),
    );

    _initialized = true;
  }
}
