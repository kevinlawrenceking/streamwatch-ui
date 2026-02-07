import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../shared/bloc/auth_session_bloc.dart';
import '../../shared/errors/failures/failure.dart';
import '../providers/rest_client.dart';

/// Interface for authentication operations.
///
/// All data sources that need authentication will depend on this interface,
/// allowing for easy swapping between dev bypass and production implementations.
abstract class IAuthDataSource {
  /// Gets the current authentication token.
  ///
  /// Returns [Right] with the token if authenticated.
  /// Returns [Left] with [AuthFailure] or [SessionExpiredFailure] otherwise.
  Future<Either<Failure, String>> getAuthToken();

  /// Authenticates with username and password.
  ///
  /// Returns [Right] with the auth token on success.
  /// Returns [Left] with [AuthFailure] on failure.
  Future<Either<Failure, String>> authenticate({
    required String username,
    required String password,
  });

  /// Logs out and clears stored credentials.
  Future<Either<Failure, void>> logout();

  /// Checks if the user is currently authenticated.
  Future<bool> isAuthenticated();
}

/// Development bypass implementation that skips authentication.
///
/// Use this during development when no authentication backend is available.
/// Returns an empty token so no Authorization header is sent.
/// Swap to [ProdAuthDataSource] when production auth is ready.
class DevAuthDataSource implements IAuthDataSource {
  @override
  Future<Either<Failure, String>> getAuthToken() async {
    // Return empty string so no Authorization header is added
    // (RestClient checks authToken.isNotEmpty before adding header)
    return const Right('');
  }

  @override
  Future<Either<Failure, String>> authenticate({
    required String username,
    required String password,
  }) async {
    // Always succeed in dev mode
    return const Right('');
  }

  @override
  Future<Either<Failure, void>> logout() async {
    return const Right(null);
  }

  @override
  Future<bool> isAuthenticated() async {
    return true; // Always authenticated in dev
  }
}

/// Production implementation that authenticates against the StreamWatch API.
///
/// Uses FlutterSecureStorage for token persistence and JWT decoding for
/// expiry checking. Login endpoint: POST /api/v1/auth with x-username
/// and x-password headers.
class ProdAuthDataSource implements IAuthDataSource {
  final IRestClient _client;
  final FlutterSecureStorage _storage;
  final AuthSessionBloc _authSessionBloc;
  String? _cachedToken;

  static const _tokenKey = 'streamwatch_auth_token';

  ProdAuthDataSource({
    required IRestClient client,
    required AuthSessionBloc authSessionBloc,
    FlutterSecureStorage? storage,
  })  : _client = client,
        _authSessionBloc = authSessionBloc,
        _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<Either<Failure, String>> authenticate({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        endPoint: '/api/v1/auth',
        headers: {
          'x-username': username,
          'x-password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String;
        _cachedToken = token;
        await _storage.write(key: _tokenKey, value: token);
        return Right(token);
      }

      if (response.statusCode == 401) {
        final failure = HttpFailure.fromResponse(response);
        return Left(AuthFailure(failure.message));
      }

      return Left(HttpFailure.fromResponse(response));
    } catch (e) {
      return Left(NetworkFailure('Login failed: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> getAuthToken() async {
    // Try cached token first
    if (_cachedToken != null && !_isTokenExpired(_cachedToken!)) {
      return Right(_cachedToken!);
    }

    // Try stored token
    final stored = await _storage.read(key: _tokenKey);
    if (stored != null && stored.isNotEmpty && !_isTokenExpired(stored)) {
      _cachedToken = stored;
      return Right(stored);
    }

    // Token expired — try refresh
    final tokenForRefresh = stored ?? _cachedToken;
    if (tokenForRefresh != null && tokenForRefresh.isNotEmpty) {
      final refreshResult = await _refreshToken(tokenForRefresh);
      if (refreshResult != null) {
        return Right(refreshResult);
      }
    }

    // Refresh failed or no token — session expired
    _cachedToken = null;
    await _storage.delete(key: _tokenKey);
    _authSessionBloc.add(const SessionExpiredEvent());
    return const Left(SessionExpiredFailure());
  }

  @override
  Future<Either<Failure, void>> logout() async {
    _cachedToken = null;
    await _storage.delete(key: _tokenKey);
    return const Right(null);
  }

  @override
  Future<bool> isAuthenticated() async {
    final result = await getAuthToken();
    return result.isRight();
  }

  /// Attempts to refresh the token via GET /api/v1/token.
  /// Returns the new token on success, null on failure.
  Future<String?> _refreshToken(String currentToken) async {
    try {
      final response = await _client.get(
        endPoint: '/api/v1/token',
        authToken: currentToken,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final newToken = data['token'] as String;
        _cachedToken = newToken;
        await _storage.write(key: _tokenKey, value: newToken);
        return newToken;
      }
    } catch (_) {
      // Refresh failed — will fall through to session expired
    }
    return null;
  }

  /// Checks if a JWT token is expired by decoding the payload.
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = json.decode(payload) as Map<String, dynamic>;
      final exp = data['exp'] as int?;
      if (exp == null) return true;
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      // Treat as expired 30 seconds early to avoid edge-case race
      return DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 30)));
    } catch (_) {
      return true;
    }
  }
}
