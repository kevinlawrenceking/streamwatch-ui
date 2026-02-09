import 'package:equatable/equatable.dart';

/// Base class for users management events.
abstract class UsersEvent extends Equatable {
  const UsersEvent();

  @override
  List<Object?> get props => [];
}

/// Load the users list.
class LoadUsersEvent extends UsersEvent {
  const LoadUsersEvent();
}

/// Search users by query string.
class SearchUsersEvent extends UsersEvent {
  final String query;

  const SearchUsersEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Create a new user.
class CreateUserEvent extends UsersEvent {
  final Map<String, dynamic> request;

  const CreateUserEvent(this.request);

  @override
  List<Object?> get props => [request];
}

/// Update an existing user.
class UpdateUserEvent extends UsersEvent {
  final String id;
  final Map<String, dynamic> request;

  const UpdateUserEvent(this.id, this.request);

  @override
  List<Object?> get props => [id, request];
}
