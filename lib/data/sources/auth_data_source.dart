import 'package:dartz/dartz.dart';
import '../../shared/errors/failures/failure.dart';

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

// TODO: Implement ProdAuthDataSource when production auth is ready
// This will use:
// - FlutterSecureStorage for token persistence
// - JWT decoding for token validation
// - Real API calls for authentication
//
// class ProdAuthDataSource implements IAuthDataSource {
//   final IRestClient _client;
//   final FlutterSecureStorage _storage;
//   String? _cachedToken;
//
//   // Implementation with real auth...
// }
