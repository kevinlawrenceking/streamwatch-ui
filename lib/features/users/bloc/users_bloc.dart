import 'package:bloc/bloc.dart';

import '../../../data/sources/user_data_source.dart';
import 'users_event.dart';
import 'users_state.dart';

/// BLoC for the users management feature.
///
/// Handles listing, searching, creating, and updating users.
/// Uses [IUserDataSource] for all API operations.
class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final IUserDataSource _userDataSource;
  String _currentQuery = '';

  UsersBloc({
    required IUserDataSource userDataSource,
  })  : _userDataSource = userDataSource,
        super(const UsersInitial()) {
    on<LoadUsersEvent>(_onLoadUsers);
    on<SearchUsersEvent>(_onSearchUsers);
    on<CreateUserEvent>(_onCreateUser);
    on<UpdateUserEvent>(_onUpdateUser);
  }

  Future<void> _onLoadUsers(
    LoadUsersEvent event,
    Emitter<UsersState> emit,
  ) async {
    emit(const UsersLoading());

    final result = await _userDataSource.listUsers(
      query: _currentQuery.isNotEmpty ? _currentQuery : null,
      limit: 50,
    );

    result.fold(
      (failure) => emit(UsersError(failure)),
      (response) => emit(UsersLoaded(
        users: response.users,
        total: response.total,
        query: _currentQuery,
      )),
    );
  }

  Future<void> _onSearchUsers(
    SearchUsersEvent event,
    Emitter<UsersState> emit,
  ) async {
    _currentQuery = event.query;
    emit(const UsersLoading());

    final result = await _userDataSource.listUsers(
      query: event.query.isNotEmpty ? event.query : null,
      limit: 50,
    );

    result.fold(
      (failure) => emit(UsersError(failure)),
      (response) => emit(UsersLoaded(
        users: response.users,
        total: response.total,
        query: event.query,
      )),
    );
  }

  Future<void> _onCreateUser(
    CreateUserEvent event,
    Emitter<UsersState> emit,
  ) async {
    emit(const UserSaving());

    final result = await _userDataSource.createUser(event.request);

    await result.fold(
      (failure) async => emit(UserSaveError(failure.message)),
      (_) async {
        emit(const UserSaved('User created successfully'));
        // Reload the list
        final listResult = await _userDataSource.listUsers(
          query: _currentQuery.isNotEmpty ? _currentQuery : null,
          limit: 50,
        );
        listResult.fold(
          (failure) => emit(UsersError(failure)),
          (response) => emit(UsersLoaded(
            users: response.users,
            total: response.total,
            query: _currentQuery,
          )),
        );
      },
    );
  }

  Future<void> _onUpdateUser(
    UpdateUserEvent event,
    Emitter<UsersState> emit,
  ) async {
    emit(const UserSaving());

    final result = await _userDataSource.updateUser(event.id, event.request);

    await result.fold(
      (failure) async => emit(UserSaveError(failure.message)),
      (_) async {
        emit(const UserSaved('User updated successfully'));
        // Reload the list
        final listResult = await _userDataSource.listUsers(
          query: _currentQuery.isNotEmpty ? _currentQuery : null,
          limit: 50,
        );
        listResult.fold(
          (failure) => emit(UsersError(failure)),
          (response) => emit(UsersLoaded(
            users: response.users,
            total: response.total,
            query: _currentQuery,
          )),
        );
      },
    );
  }
}
