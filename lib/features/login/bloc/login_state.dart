import 'package:equatable/equatable.dart';

import '../../../shared/errors/failures/failure.dart';

/// Base class for login states.
abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

/// Initial state — show the login form.
class LoginInitial extends LoginState {
  const LoginInitial();
}

/// Loading state — login request in progress.
class LoginLoading extends LoginState {
  const LoginLoading();
}

/// Success state — user authenticated.
class LoginSuccess extends LoginState {
  const LoginSuccess();
}

/// Failure state — login failed with a reason.
class LoginFailure extends LoginState {
  final Failure failure;

  const LoginFailure({required this.failure});

  @override
  List<Object?> get props => [failure];
}
