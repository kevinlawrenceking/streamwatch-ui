import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../data/providers/rest_client.dart';
import '../../../../data/sources/auth_data_source.dart';
import '../../../../shared/errors/exception_handler.dart';
import '../../../../shared/errors/failures/failure.dart';
import '../models/podcast.dart';
import '../models/podcast_episode.dart';
import '../models/podcast_platform.dart';
import '../models/podcast_schedule.dart';

/// Generic paginated response wrapper.
class PaginatedResponse<T> extends Equatable {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;

  const PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => page * pageSize < total;

  @override
  List<Object?> get props => [items, total, page, pageSize];
}

/// Interface for podcast data operations.
abstract class IPodcastDataSource {
  Future<Either<Failure, PaginatedResponse<PodcastModel>>> listPodcasts({
    int page = 1,
    int pageSize = 20,
    bool includeInactive = false,
  });

  Future<Either<Failure, PodcastModel>> createPodcast(
      Map<String, dynamic> body);

  Future<Either<Failure, PodcastModel>> getPodcast(String id);

  Future<Either<Failure, PodcastModel>> updatePodcast(
      String id, Map<String, dynamic> body);

  Future<Either<Failure, void>> deactivatePodcast(String id);

  Future<Either<Failure, void>> activatePodcast(String id);

  Future<Either<Failure, List<PodcastPlatformModel>>> listPlatforms(
      String podcastId);

  Future<Either<Failure, PodcastPlatformModel>> createPlatform(
      String podcastId, Map<String, dynamic> body);

  Future<Either<Failure, PodcastPlatformModel>> getPlatform(String platformId);

  Future<Either<Failure, PodcastPlatformModel>> updatePlatform(
      String platformId, Map<String, dynamic> body);

  Future<Either<Failure, void>> deletePlatform(String platformId);

  Future<Either<Failure, List<PodcastScheduleModel>>> listSchedules(
      String podcastId);

  Future<Either<Failure, PodcastScheduleModel>> createSchedule(
      String podcastId, Map<String, dynamic> body);

  Future<Either<Failure, PodcastScheduleModel>> getSchedule(String scheduleId);

  Future<Either<Failure, PodcastScheduleModel>> updateSchedule(
      String scheduleId, Map<String, dynamic> body);

  Future<Either<Failure, void>> deleteSchedule(String scheduleId);

  Future<Either<Failure, PaginatedResponse<PodcastEpisodeModel>>> listEpisodes(
    String podcastId, {
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, PodcastEpisodeModel>> getEpisode(String episodeId);
}

/// HTTP implementation of [IPodcastDataSource].
class PodcastDataSource implements IPodcastDataSource {
  final IAuthDataSource _auth;
  final IRestClient _client;

  const PodcastDataSource({
    required IAuthDataSource auth,
    required IRestClient client,
  })  : _auth = auth,
        _client = client;

  // ---------------------------------------------------------------------------
  // Podcasts
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, PaginatedResponse<PodcastModel>>> listPodcasts({
    int page = 1,
    int pageSize = 20,
    bool includeInactive = false,
  }) =>
      ExceptionHandler<PaginatedResponse<PodcastModel>>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/podcasts',
              authToken: authToken,
              queryParams: {
                'page': page.toString(),
                'page_size': pageSize.toString(),
                if (includeInactive) 'include_inactive': 'true',
              },
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final decoded = json.decode(response.body);
            if (decoded is Map<String, dynamic>) {
              final itemsList = decoded['items'] as List? ?? [];
              final items = itemsList
                  .map((e) =>
                      PodcastModel.fromJsonDto(e as Map<String, dynamic>))
                  .toList();
              return Right(PaginatedResponse(
                items: items,
                total: decoded['total'] as int? ?? items.length,
                page: decoded['page'] as int? ?? page,
                pageSize: decoded['page_size'] as int? ?? pageSize,
              ));
            }

            // Fallback: plain list response
            if (decoded is List) {
              final items = decoded
                  .map((e) =>
                      PodcastModel.fromJsonDto(e as Map<String, dynamic>))
                  .toList();
              return Right(PaginatedResponse(
                items: items,
                total: items.length,
                page: 1,
                pageSize: items.length,
              ));
            }

            return Right(PaginatedResponse(
              items: const [],
              total: 0,
              page: page,
              pageSize: pageSize,
            ));
          },
        );
      }).call();

  @override
  Future<Either<Failure, PodcastModel>> createPodcast(
          Map<String, dynamic> body) =>
      ExceptionHandler<PodcastModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.post(
              endPoint: '/api/v1/podcasts',
              authToken: authToken,
              body: body,
            );

            if (response.statusCode != HttpStatus.created &&
                response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final decoded = json.decode(response.body);
            return Right(
                PodcastModel.fromJsonDto(decoded as Map<String, dynamic>));
          },
        );
      }).call();

  @override
  Future<Either<Failure, PodcastModel>> getPodcast(String id) =>
      ExceptionHandler<PodcastModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/podcasts/$id',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final decoded = json.decode(response.body);
            return Right(
                PodcastModel.fromJsonDto(decoded as Map<String, dynamic>));
          },
        );
      }).call();

  @override
  Future<Either<Failure, PodcastModel>> updatePodcast(
          String id, Map<String, dynamic> body) =>
      ExceptionHandler<PodcastModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.patch(
              endPoint: '/api/v1/podcasts/$id',
              authToken: authToken,
              body: body,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final decoded = json.decode(response.body);
            return Right(
                PodcastModel.fromJsonDto(decoded as Map<String, dynamic>));
          },
        );
      }).call();

  @override
  Future<Either<Failure, void>> deactivatePodcast(String id) =>
      ExceptionHandler<void>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.post(
              endPoint: '/api/v1/podcasts/$id/deactivate',
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
  Future<Either<Failure, void>> activatePodcast(String id) =>
      ExceptionHandler<void>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.post(
              endPoint: '/api/v1/podcasts/$id/activate',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            return const Right(null);
          },
        );
      }).call();

  // ---------------------------------------------------------------------------
  // Platforms
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, List<PodcastPlatformModel>>> listPlatforms(
          String podcastId) =>
      ExceptionHandler<List<PodcastPlatformModel>>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/podcasts/$podcastId/platforms',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final body = response.body;
            if (body.isEmpty || body == 'null') return const Right([]);

            final decoded = json.decode(body);
            if (decoded is! List) return const Right([]);

            return Right(decoded
                .map((e) => PodcastPlatformModel.fromJsonDto(
                    e as Map<String, dynamic>))
                .toList());
          },
        );
      }).call();

  @override
  Future<Either<Failure, PodcastPlatformModel>> createPlatform(
          String podcastId, Map<String, dynamic> body) =>
      ExceptionHandler<PodcastPlatformModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.post(
              endPoint: '/api/v1/podcasts/$podcastId/platforms',
              authToken: authToken,
              body: body,
            );

            if (response.statusCode != HttpStatus.created &&
                response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final decoded = json.decode(response.body);
            return Right(PodcastPlatformModel.fromJsonDto(
                decoded as Map<String, dynamic>));
          },
        );
      }).call();

  @override
  Future<Either<Failure, PodcastPlatformModel>> getPlatform(
          String platformId) =>
      ExceptionHandler<PodcastPlatformModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/podcast-platforms/$platformId',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final decoded = json.decode(response.body);
            return Right(PodcastPlatformModel.fromJsonDto(
                decoded as Map<String, dynamic>));
          },
        );
      }).call();

  @override
  Future<Either<Failure, PodcastPlatformModel>> updatePlatform(
          String platformId, Map<String, dynamic> body) =>
      ExceptionHandler<PodcastPlatformModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.patch(
              endPoint: '/api/v1/podcast-platforms/$platformId',
              authToken: authToken,
              body: body,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final decoded = json.decode(response.body);
            return Right(PodcastPlatformModel.fromJsonDto(
                decoded as Map<String, dynamic>));
          },
        );
      }).call();

  @override
  Future<Either<Failure, void>> deletePlatform(String platformId) =>
      ExceptionHandler<void>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.delete(
              endPoint: '/api/v1/podcast-platforms/$platformId',
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

  // ---------------------------------------------------------------------------
  // Schedules
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, List<PodcastScheduleModel>>> listSchedules(
          String podcastId) =>
      ExceptionHandler<List<PodcastScheduleModel>>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/podcasts/$podcastId/schedules',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final body = response.body;
            if (body.isEmpty || body == 'null') return const Right([]);

            final decoded = json.decode(body);
            if (decoded is! List) return const Right([]);

            return Right(decoded
                .map((e) => PodcastScheduleModel.fromJsonDto(
                    e as Map<String, dynamic>))
                .toList());
          },
        );
      }).call();

  @override
  Future<Either<Failure, PodcastScheduleModel>> createSchedule(
          String podcastId, Map<String, dynamic> body) =>
      ExceptionHandler<PodcastScheduleModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.post(
              endPoint: '/api/v1/podcasts/$podcastId/schedules',
              authToken: authToken,
              body: body,
            );

            if (response.statusCode != HttpStatus.created &&
                response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final decoded = json.decode(response.body);
            return Right(PodcastScheduleModel.fromJsonDto(
                decoded as Map<String, dynamic>));
          },
        );
      }).call();

  @override
  Future<Either<Failure, PodcastScheduleModel>> getSchedule(
          String scheduleId) =>
      ExceptionHandler<PodcastScheduleModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/podcast-schedules/$scheduleId',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final decoded = json.decode(response.body);
            return Right(PodcastScheduleModel.fromJsonDto(
                decoded as Map<String, dynamic>));
          },
        );
      }).call();

  @override
  Future<Either<Failure, PodcastScheduleModel>> updateSchedule(
          String scheduleId, Map<String, dynamic> body) =>
      ExceptionHandler<PodcastScheduleModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.patch(
              endPoint: '/api/v1/podcast-schedules/$scheduleId',
              authToken: authToken,
              body: body,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final decoded = json.decode(response.body);
            return Right(PodcastScheduleModel.fromJsonDto(
                decoded as Map<String, dynamic>));
          },
        );
      }).call();

  @override
  Future<Either<Failure, void>> deleteSchedule(String scheduleId) =>
      ExceptionHandler<void>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.delete(
              endPoint: '/api/v1/podcast-schedules/$scheduleId',
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

  // ---------------------------------------------------------------------------
  // Episodes
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, PaginatedResponse<PodcastEpisodeModel>>> listEpisodes(
    String podcastId, {
    int page = 1,
    int pageSize = 20,
  }) =>
      ExceptionHandler<PaginatedResponse<PodcastEpisodeModel>>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/podcast-episodes',
              authToken: authToken,
              queryParams: {
                'podcast_id': podcastId,
                'page': page.toString(),
                'page_size': pageSize.toString(),
              },
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final decoded = json.decode(response.body);
            if (decoded is Map<String, dynamic>) {
              final itemsList = decoded['items'] as List? ?? [];
              final items = itemsList
                  .map((e) => PodcastEpisodeModel.fromJsonDto(
                      e as Map<String, dynamic>))
                  .toList();
              return Right(PaginatedResponse(
                items: items,
                total: decoded['total'] as int? ?? items.length,
                page: decoded['page'] as int? ?? page,
                pageSize: decoded['page_size'] as int? ?? pageSize,
              ));
            }

            if (decoded is List) {
              final items = decoded
                  .map((e) => PodcastEpisodeModel.fromJsonDto(
                      e as Map<String, dynamic>))
                  .toList();
              return Right(PaginatedResponse(
                items: items,
                total: items.length,
                page: 1,
                pageSize: items.length,
              ));
            }

            return Right(PaginatedResponse(
              items: const [],
              total: 0,
              page: page,
              pageSize: pageSize,
            ));
          },
        );
      }).call();

  @override
  Future<Either<Failure, PodcastEpisodeModel>> getEpisode(String episodeId) =>
      ExceptionHandler<PodcastEpisodeModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/podcast-episodes/$episodeId',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final decoded = json.decode(response.body);
            return Right(PodcastEpisodeModel.fromJsonDto(
                decoded as Map<String, dynamic>));
          },
        );
      }).call();
}
