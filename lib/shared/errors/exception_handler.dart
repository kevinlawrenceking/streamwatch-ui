import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'failures/failure.dart';

/// Wraps async operations with standardized exception handling.
///
/// Converts exceptions to appropriate [Failure] types for functional
/// error handling throughout the application.
///
/// Usage:
/// ```dart
/// Future<Either<Failure, User>> getUser() =>
///   ExceptionHandler<User>(() async {
///     final response = await client.get('/user');
///     return Right(User.fromJson(response));
///   })();
/// ```
class ExceptionHandler<TResult> {
  final Future<Either<Failure, TResult>> Function() _action;

  const ExceptionHandler(this._action);

  /// Executes the wrapped action with exception handling.
  Future<Either<Failure, TResult>> call() async {
    try {
      return await _action();
    } on SocketException catch (e) {
      // More detailed socket error message
      return Left(NetworkFailure('Unable to connect to server: ${e.message}'));
    } on http.ClientException catch (e) {
      // Include the actual error message from ClientException
      return Left(NetworkFailure('Network request failed: ${e.message}'));
    } on FormatException catch (e) {
      return Left(GeneralFailure('Data format error: ${e.message}'));
    } on Exception catch (e) {
      return Left(GeneralFailure(e.toString()));
    } catch (e) {
      return Left(GeneralFailure('Unexpected error: $e'));
    }
  }
}
