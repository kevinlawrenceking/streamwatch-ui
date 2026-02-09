import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';

import '../models/collection_model.dart';
import '../models/job_model.dart';
import '../providers/rest_client.dart';
import 'auth_data_source.dart';
import '../../shared/errors/exception_handler.dart';
import '../../shared/errors/failures/failure.dart';

/// Interface for collection-related data operations.
abstract class ICollectionDataSource {
  /// Lists collections visible to the current user (owned + public).
  Future<Either<Failure, List<CollectionModel>>> getCollections();

  /// Creates a new collection.
  Future<Either<Failure, CollectionModel>> createCollection({
    required String name,
    String? visibility,
    List<String>? tags,
  });

  /// Updates a collection.
  Future<Either<Failure, CollectionModel>> updateCollection(
    String id, {
    String? name,
    String? visibility,
    String? status,
  });

  /// Sets a collection as the user's default.
  Future<Either<Failure, void>> makeDefault(String id);

  /// Lists videos in a collection.
  Future<Either<Failure, List<JobModel>>> getCollectionVideos(String id,
      {int limit = 200});

  /// Adds videos to a collection.
  Future<Either<Failure, void>> addVideosToCollection(
      String id, List<String> videoIds);

  /// Removes a video from a collection.
  Future<Either<Failure, void>> removeVideoFromCollection(
      String collectionId, String videoId);
}

/// HTTP implementation of ICollectionDataSource.
class CollectionDataSource implements ICollectionDataSource {
  final IAuthDataSource _auth;
  final IRestClient _client;

  const CollectionDataSource({
    required IAuthDataSource auth,
    required IRestClient client,
  })  : _auth = auth,
        _client = client;

  @override
  Future<Either<Failure, List<CollectionModel>>> getCollections() =>
      ExceptionHandler<List<CollectionModel>>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/collections',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final body = response.body;
            if (body.isEmpty || body == 'null') {
              return const Right([]);
            }

            final decoded = json.decode(body);
            if (decoded is! List) {
              return const Right([]);
            }

            final collections = decoded
                .map((e) =>
                    CollectionModel.fromJson(e as Map<String, dynamic>))
                .toList();
            return Right(collections);
          },
        );
      }).call();

  @override
  Future<Either<Failure, CollectionModel>> createCollection({
    required String name,
    String? visibility,
    List<String>? tags,
  }) =>
      ExceptionHandler<CollectionModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final body = <String, dynamic>{'name': name};
            if (visibility != null) body['visibility'] = visibility;
            if (tags != null && tags.isNotEmpty) body['tags'] = tags;

            final response = await _client.post(
              endPoint: '/api/v1/collections',
              authToken: authToken,
              body: body,
            );

            if (response.statusCode != HttpStatus.created) {
              return Left(HttpFailure.fromResponse(response));
            }

            final decoded = json.decode(response.body);
            return Right(
                CollectionModel.fromJson(decoded as Map<String, dynamic>));
          },
        );
      }).call();

  @override
  Future<Either<Failure, CollectionModel>> updateCollection(
    String id, {
    String? name,
    String? visibility,
    String? status,
  }) =>
      ExceptionHandler<CollectionModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final body = <String, dynamic>{};
            if (name != null) body['name'] = name;
            if (visibility != null) body['visibility'] = visibility;
            if (status != null) body['status'] = status;

            final response = await _client.patch(
              endPoint: '/api/v1/collections/$id',
              authToken: authToken,
              body: body,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final decoded = json.decode(response.body);
            return Right(
                CollectionModel.fromJson(decoded as Map<String, dynamic>));
          },
        );
      }).call();

  @override
  Future<Either<Failure, void>> makeDefault(String id) =>
      ExceptionHandler<void>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.post(
              endPoint: '/api/v1/collections/$id/make-default',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            return const Right(null);
          },
        );
      }).call();

  @override
  Future<Either<Failure, List<JobModel>>> getCollectionVideos(String id,
          {int limit = 200}) =>
      ExceptionHandler<List<JobModel>>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/collections/$id/videos',
              authToken: authToken,
              queryParams: {'limit': limit.toString()},
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final body = response.body;
            if (body.isEmpty || body == 'null') {
              return const Right([]);
            }

            final decoded = json.decode(body);
            if (decoded is! List) {
              return const Right([]);
            }

            final jobs = decoded
                .map((e) => JobModel.fromJsonDto(e as Map<String, dynamic>))
                .toList();
            return Right(jobs);
          },
        );
      }).call();

  @override
  Future<Either<Failure, void>> addVideosToCollection(
          String id, List<String> videoIds) =>
      ExceptionHandler<void>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.post(
              endPoint: '/api/v1/collections/$id/videos',
              authToken: authToken,
              body: {'video_ids': videoIds},
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            return const Right(null);
          },
        );
      }).call();

  @override
  Future<Either<Failure, void>> removeVideoFromCollection(
          String collectionId, String videoId) =>
      ExceptionHandler<void>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.delete(
              endPoint: '/api/v1/collections/$collectionId/videos/$videoId',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            return const Right(null);
          },
        );
      }).call();
}
