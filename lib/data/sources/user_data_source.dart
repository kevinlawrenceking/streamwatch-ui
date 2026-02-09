import 'dart:convert';

import 'package:dartz/dartz.dart';

import '../../shared/errors/failures/failure.dart';
import '../models/user_profile_model.dart';
import '../providers/rest_client.dart';
import 'auth_data_source.dart';

/// Interface for user-related data operations.
///
/// Provides methods for the current user profile (getMe, logout)
/// and admin-only user management (list, get, create, update).
abstract class IUserDataSource {
  /// Gets the current authenticated user profile.
  /// Calls GET /api/v1/me.
  Future<Either<Failure, UserProfileModel>> getMe();

  /// Logs out the current user by revoking the server-side session.
  /// Calls POST /api/v1/logout.
  Future<Either<Failure, void>> logout();

  /// Lists users with optional search query and pagination.
  /// Admin-only. Calls GET /api/v1/users.
  Future<Either<Failure, UserListResponse>> listUsers({
    String? query,
    int? limit,
    int? offset,
  });

  /// Gets a single user by ID.
  /// Admin-only. Calls GET /api/v1/users/{id}.
  Future<Either<Failure, UserProfileModel>> getUser(String id);

  /// Creates a new user.
  /// Admin-only. Calls POST /api/v1/users.
  Future<Either<Failure, UserProfileModel>> createUser(
      Map<String, dynamic> request);

  /// Updates an existing user.
  /// Admin-only. Calls PATCH /api/v1/users/{id}.
  Future<Either<Failure, UserProfileModel>> updateUser(
      String id, Map<String, dynamic> request);
}

/// Production implementation that calls the StreamWatch API.
///
/// Uses [IAuthDataSource] for authentication tokens and [IRestClient]
/// for HTTP requests, following the same pattern as JobDataSource.
class ProdUserDataSource implements IUserDataSource {
  final IAuthDataSource _auth;
  final IRestClient _client;

  ProdUserDataSource({
    required IAuthDataSource auth,
    required IRestClient client,
  })  : _auth = auth,
        _client = client;

  @override
  Future<Either<Failure, UserProfileModel>> getMe() async {
    final tokenResult = await _auth.getAuthToken();
    return tokenResult.fold(
      (failure) => Left(failure),
      (token) async {
        try {
          final response = await _client.get(
            endPoint: '/api/v1/me',
            authToken: token,
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body) as Map<String, dynamic>;
            return Right(UserProfileModel.fromJson(data));
          }

          return Left(HttpFailure.fromResponse(response));
        } catch (e) {
          return Left(NetworkFailure('Failed to load profile: $e'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, void>> logout() async {
    final tokenResult = await _auth.getAuthToken();
    return tokenResult.fold(
      (failure) => const Right(null), // If no token, nothing to revoke
      (token) async {
        try {
          await _client.post(
            endPoint: '/api/v1/logout',
            authToken: token,
          );
        } catch (_) {
          // Best effort - if server revocation fails, we still clear locally
        }
        return const Right(null);
      },
    );
  }

  @override
  Future<Either<Failure, UserListResponse>> listUsers({
    String? query,
    int? limit,
    int? offset,
  }) async {
    final tokenResult = await _auth.getAuthToken();
    return tokenResult.fold(
      (failure) => Left(failure),
      (token) async {
        try {
          final queryParams = <String, String>{};
          if (query != null && query.isNotEmpty) queryParams['q'] = query;
          if (limit != null) queryParams['limit'] = limit.toString();
          if (offset != null) queryParams['offset'] = offset.toString();

          final response = await _client.get(
            endPoint: '/api/v1/users',
            authToken: token,
            queryParams: queryParams.isNotEmpty ? queryParams : null,
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body) as Map<String, dynamic>;
            return Right(UserListResponse.fromJson(data));
          }

          if (response.statusCode == 403) {
            return const Left(
              HttpFailure(statusCode: 403, message: 'Admin access required'),
            );
          }

          return Left(HttpFailure.fromResponse(response));
        } catch (e) {
          return Left(NetworkFailure('Failed to load users: $e'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, UserProfileModel>> getUser(String id) async {
    final tokenResult = await _auth.getAuthToken();
    return tokenResult.fold(
      (failure) => Left(failure),
      (token) async {
        try {
          final response = await _client.get(
            endPoint: '/api/v1/users/$id',
            authToken: token,
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body) as Map<String, dynamic>;
            return Right(UserProfileModel.fromJson(data));
          }

          return Left(HttpFailure.fromResponse(response));
        } catch (e) {
          return Left(NetworkFailure('Failed to load user: $e'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, UserProfileModel>> createUser(
      Map<String, dynamic> request) async {
    final tokenResult = await _auth.getAuthToken();
    return tokenResult.fold(
      (failure) => Left(failure),
      (token) async {
        try {
          final response = await _client.post(
            endPoint: '/api/v1/users',
            authToken: token,
            body: request,
          );

          if (response.statusCode == 201 || response.statusCode == 200) {
            final data = json.decode(response.body) as Map<String, dynamic>;
            return Right(UserProfileModel.fromJson(data));
          }

          return Left(HttpFailure.fromResponse(response));
        } catch (e) {
          return Left(NetworkFailure('Failed to create user: $e'));
        }
      },
    );
  }

  @override
  Future<Either<Failure, UserProfileModel>> updateUser(
      String id, Map<String, dynamic> request) async {
    final tokenResult = await _auth.getAuthToken();
    return tokenResult.fold(
      (failure) => Left(failure),
      (token) async {
        try {
          final response = await _client.patch(
            endPoint: '/api/v1/users/$id',
            authToken: token,
            body: request,
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body) as Map<String, dynamic>;
            return Right(UserProfileModel.fromJson(data));
          }

          return Left(HttpFailure.fromResponse(response));
        } catch (e) {
          return Left(NetworkFailure('Failed to update user: $e'));
        }
      },
    );
  }
}

/// Development bypass implementation with mock data.
///
/// Used during development when no authentication backend is available.
class DevUserDataSource implements IUserDataSource {
  @override
  Future<Either<Failure, UserProfileModel>> getMe() async {
    return Right(UserProfileModel(
      id: 'dev-user-001',
      username: 'devuser',
      firstName: 'Dev',
      lastName: 'User',
      role: 'admin',
      sid: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<Either<Failure, void>> logout() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserListResponse>> listUsers({
    String? query,
    int? limit,
    int? offset,
  }) async {
    return Right(UserListResponse(
      users: [
        UserProfileModel(
          id: 'dev-user-001',
          username: 'devuser',
          firstName: 'Dev',
          lastName: 'User',
          role: 'admin',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ],
      total: 1,
    ));
  }

  @override
  Future<Either<Failure, UserProfileModel>> getUser(String id) async {
    return Right(UserProfileModel(
      id: id,
      username: 'devuser',
      firstName: 'Dev',
      lastName: 'User',
      role: 'admin',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<Either<Failure, UserProfileModel>> createUser(
      Map<String, dynamic> request) async {
    return Right(UserProfileModel(
      id: 'dev-new-user',
      username: (request['username'] as String?) ?? 'newuser',
      firstName: (request['first_name'] as String?) ?? '',
      lastName: (request['last_name'] as String?) ?? '',
      role: (request['role'] as String?) ?? 'user',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<Either<Failure, UserProfileModel>> updateUser(
      String id, Map<String, dynamic> request) async {
    return Right(UserProfileModel(
      id: id,
      username: (request['username'] as String?) ?? 'updateduser',
      firstName: (request['first_name'] as String?) ?? '',
      lastName: (request['last_name'] as String?) ?? '',
      role: (request['role'] as String?) ?? 'user',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }
}
