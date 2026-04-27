import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../data/providers/rest_client.dart';
import '../../data/sources/auth_data_source.dart';
import '../errors/exception_handler.dart';
import '../errors/failures/failure.dart';

/// Shared HTTP helpers for DataSource implementations.
///
/// Promotes the 6 private helpers introduced in `PodcastDataSource`
/// (WO-077 / LSW-015 / KB §30) to a static utility so all DataSources
/// share the auth-token + ExceptionHandler + status-code boilerplate
/// without duplication. Locked in WO-078 / LSW-016 Plan-Lock #2
/// (Option A-revised: 2-arg first-args -- both `auth` and `client`,
/// because the original helpers close over `_auth` as well as `_client`,
/// per Phase 1.11 Discovery / F-1).
///
/// Naming convention aligns with §30.10: `path:` (not `endPoint:`),
/// `fromJsonDto:` (not `fromJson:`).
abstract class HttpHelpers {
  HttpHelpers._();

  /// GET that decodes a single JSON object response. Accepts only HTTP 200.
  static Future<Either<Failure, T>> getJsonSingle<T>({
    required IAuthDataSource auth,
    required IRestClient client,
    required String path,
    required T Function(Map<String, dynamic>) fromJsonDto,
  }) =>
      ExceptionHandler<T>(() async {
        final tokenResult = await auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await client.get(
              endPoint: path,
              authToken: authToken,
            );
            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }
            final decoded = json.decode(response.body);
            return Right(fromJsonDto(decoded as Map<String, dynamic>));
          },
        );
      }).call();

  /// GET that decodes a JSON array response into List<T>. Accepts only
  /// HTTP 200. Empty body / `null` body / non-list body all yield
  /// `Right([])` rather than a parse failure (per §30.8 D2).
  static Future<Either<Failure, List<T>>> getJsonList<T>({
    required IAuthDataSource auth,
    required IRestClient client,
    required String path,
    required T Function(Map<String, dynamic>) fromJsonDto,
    Map<String, String>? queryParams,
  }) =>
      ExceptionHandler<List<T>>(() async {
        final tokenResult = await auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await client.get(
              endPoint: path,
              authToken: authToken,
              queryParams: queryParams,
            );
            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }
            final body = response.body;
            if (body.isEmpty || body == 'null') return const Right([]);
            final decoded = json.decode(body);
            if (decoded is! List) return const Right([]);
            return Right(decoded
                .map((e) => fromJsonDto(e as Map<String, dynamic>))
                .toList());
          },
        );
      }).call();

  /// POST that decodes a single JSON object response. Default
  /// `acceptedStatusCodes` is `{200, 201}`. For 207 Multi-Status envelopes
  /// (e.g. batch-trigger), pass `acceptedStatusCodes: const {207}` and
  /// model the envelope as the `T` type.
  static Future<Either<Failure, T>> postJsonSingle<T>({
    required IAuthDataSource auth,
    required IRestClient client,
    required String path,
    required T Function(Map<String, dynamic>) fromJsonDto,
    Map<String, dynamic>? body,
    Set<int> acceptedStatusCodes = const {HttpStatus.ok, HttpStatus.created},
  }) =>
      ExceptionHandler<T>(() async {
        final tokenResult = await auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await client.post(
              endPoint: path,
              authToken: authToken,
              body: body,
            );
            if (!acceptedStatusCodes.contains(response.statusCode)) {
              return Left(HttpFailure.fromResponse(response));
            }
            final decoded = json.decode(response.body);
            return Right(fromJsonDto(decoded as Map<String, dynamic>));
          },
        );
      }).call();

  /// PATCH that decodes a single JSON object response. Accepts only HTTP 200.
  static Future<Either<Failure, T>> patchJsonSingle<T>({
    required IAuthDataSource auth,
    required IRestClient client,
    required String path,
    required Map<String, dynamic> body,
    required T Function(Map<String, dynamic>) fromJsonDto,
  }) =>
      ExceptionHandler<T>(() async {
        final tokenResult = await auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await client.patch(
              endPoint: path,
              authToken: authToken,
              body: body,
            );
            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }
            final decoded = json.decode(response.body);
            return Right(fromJsonDto(decoded as Map<String, dynamic>));
          },
        );
      }).call();

  /// DELETE returning void. Accepts HTTP 200 OR 204 No Content.
  static Future<Either<Failure, void>> deleteVoid({
    required IAuthDataSource auth,
    required IRestClient client,
    required String path,
  }) =>
      ExceptionHandler<void>(() async {
        final tokenResult = await auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await client.delete(
              endPoint: path,
              authToken: authToken,
            );
            if (response.statusCode != HttpStatus.ok &&
                response.statusCode != HttpStatus.noContent) {
              return Left(HttpFailure.fromResponse(response));
            }
            return const Right(null);
          },
        );
      }).call();

  /// POST returning void with caller-specified status acceptance.
  /// Used for fire-and-forget endpoints whose success status is not 200,
  /// such as 202 Accepted (e.g. retry / generate-headlines / single-trigger).
  static Future<Either<Failure, void>> postVoidWithStatus({
    required IAuthDataSource auth,
    required IRestClient client,
    required String path,
    required Set<int> acceptedStatusCodes,
    Map<String, dynamic>? body,
  }) =>
      ExceptionHandler<void>(() async {
        final tokenResult = await auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await client.post(
              endPoint: path,
              authToken: authToken,
              body: body,
            );
            if (!acceptedStatusCodes.contains(response.statusCode)) {
              return Left(HttpFailure.fromResponse(response));
            }
            return const Right(null);
          },
        );
      }).call();
}
