import 'package:equatable/equatable.dart';

import '../../../data/models/user_profile_model.dart';
import '../../../shared/errors/failures/failure.dart';

/// Base class for users management states.
abstract class UsersState extends Equatable {
  const UsersState();

  @override
  List<Object?> get props => [];
}

/// Initial state before users are loaded.
class UsersInitial extends UsersState {
  const UsersInitial();
}

/// Loading state while fetching users.
class UsersLoading extends UsersState {
  const UsersLoading();
}

/// Users loaded successfully.
class UsersLoaded extends UsersState {
  final List<UserProfileModel> users;
  final int total;
  final int page;
  final String query;

  const UsersLoaded({
    required this.users,
    required this.total,
    this.page = 0,
    this.query = '',
  });

  @override
  List<Object?> get props => [users, total, page, query];
}

/// Error state when loading users fails.
class UsersError extends UsersState {
  final Failure failure;

  const UsersError(this.failure);

  @override
  List<Object?> get props => [failure];
}

/// State while saving a user (create or update).
class UserSaving extends UsersState {
  const UserSaving();
}

/// User saved successfully.
class UserSaved extends UsersState {
  final String message;

  const UserSaved(this.message);

  @override
  List<Object?> get props => [message];
}

/// Error state when saving a user fails.
class UserSaveError extends UsersState {
  final String message;

  const UserSaveError(this.message);

  @override
  List<Object?> get props => [message];
}
