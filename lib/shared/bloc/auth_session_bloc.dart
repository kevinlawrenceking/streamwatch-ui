import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// ============================================================================
// Events
// ============================================================================

/// Base class for authentication session events.
abstract class AuthSessionEvent extends Equatable {
  const AuthSessionEvent();

  @override
  List<Object?> get props => [];
}

/// Event fired when the user's session has expired.
class SessionExpiredEvent extends AuthSessionEvent {
  const SessionExpiredEvent();
}

/// Event fired when the user requests to logout.
class LogoutRequestedEvent extends AuthSessionEvent {
  const LogoutRequestedEvent();
}

/// Event fired when a session is successfully restored.
class SessionRestoredEvent extends AuthSessionEvent {
  const SessionRestoredEvent();
}

/// Event fired when login is successful.
class LoginSuccessEvent extends AuthSessionEvent {
  const LoginSuccessEvent();
}

// ============================================================================
// States
// ============================================================================

/// Base class for authentication session states.
abstract class AuthSessionState extends Equatable {
  const AuthSessionState();

  @override
  List<Object?> get props => [];
}

/// Initial state before session status is determined.
class AuthSessionInitial extends AuthSessionState {
  const AuthSessionInitial();
}

/// State when the user is authenticated.
class AuthSessionAuthenticated extends AuthSessionState {
  const AuthSessionAuthenticated();
}

/// State when the user's session has expired.
class AuthSessionExpired extends AuthSessionState {
  const AuthSessionExpired();
}

/// State when the user is not authenticated.
class AuthSessionUnauthenticated extends AuthSessionState {
  const AuthSessionUnauthenticated();
}

// ============================================================================
// BLoC
// ============================================================================

/// Global BLoC for managing application-wide authentication session state.
///
/// This is registered as a singleton and can be accessed from anywhere
/// in the app to check session status or listen for session changes.
///
/// Usage:
/// ```dart
/// BlocListener<AuthSessionBloc, AuthSessionState>(
///   listener: (context, state) {
///     if (state is AuthSessionExpired) {
///       // Redirect to login
///     }
///   },
///   child: ...
/// )
/// ```
class AuthSessionBloc extends Bloc<AuthSessionEvent, AuthSessionState> {
  AuthSessionBloc() : super(const AuthSessionInitial()) {
    on<SessionExpiredEvent>(_onSessionExpired);
    on<LogoutRequestedEvent>(_onLogoutRequested);
    on<SessionRestoredEvent>(_onSessionRestored);
    on<LoginSuccessEvent>(_onLoginSuccess);
  }

  void _onSessionExpired(
    SessionExpiredEvent event,
    Emitter<AuthSessionState> emit,
  ) {
    emit(const AuthSessionExpired());
  }

  void _onLogoutRequested(
    LogoutRequestedEvent event,
    Emitter<AuthSessionState> emit,
  ) {
    emit(const AuthSessionUnauthenticated());
  }

  void _onSessionRestored(
    SessionRestoredEvent event,
    Emitter<AuthSessionState> emit,
  ) {
    emit(const AuthSessionAuthenticated());
  }

  void _onLoginSuccess(
    LoginSuccessEvent event,
    Emitter<AuthSessionState> emit,
  ) {
    emit(const AuthSessionAuthenticated());
  }
}
