import 'package:equatable/equatable.dart';

/// Base class for login events.
abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

/// Event fired when the user submits the login form.
class LoginSubmitted extends LoginEvent {
  final String username;
  final String password;

  const LoginSubmitted({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
}

/// Event fired on mount to check for a saved session.
class CheckSavedSession extends LoginEvent {
  const CheckSavedSession();
}
