import 'package:bloc/bloc.dart';

import '../../../data/sources/auth_data_source.dart';
import '../../../shared/bloc/auth_session_bloc.dart';
import 'login_event.dart';
import 'login_state.dart';

/// BLoC for the login feature.
///
/// Handles login form submission and saved session restoration.
/// Integrates with [AuthSessionBloc] to propagate auth state globally.
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final IAuthDataSource _authDataSource;
  final AuthSessionBloc _authSessionBloc;

  LoginBloc({
    required IAuthDataSource authDataSource,
    required AuthSessionBloc authSessionBloc,
  })  : _authDataSource = authDataSource,
        _authSessionBloc = authSessionBloc,
        super(const LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<CheckSavedSession>(_onCheckSavedSession);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginLoading());

    final result = await _authDataSource.authenticate(
      username: event.username,
      password: event.password,
    );

    result.fold(
      (failure) => emit(LoginFailure(failure: failure)),
      (_) {
        _authSessionBloc.add(const LoginSuccessEvent());
        emit(const LoginSuccess());
      },
    );
  }

  Future<void> _onCheckSavedSession(
    CheckSavedSession event,
    Emitter<LoginState> emit,
  ) async {
    final isAuth = await _authDataSource.isAuthenticated();
    if (isAuth) {
      _authSessionBloc.add(const SessionRestoredEvent());
      emit(const LoginSuccess());
    }
  }
}
