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
import '../models/podcast_headline_candidate.dart';
import '../models/podcast_notification.dart';
import '../models/podcast_platform.dart';
import '../models/podcast_schedule.dart';
import '../models/podcast_transcript.dart';

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

  // ---------------------------------------------------------------------------
  // Episode operations (LSW-007-A / WO-059) -- added by WO-077 / LSW-015
  // ---------------------------------------------------------------------------

  /// PATCH /api/v1/podcast-episodes/{id}
  Future<Either<Failure, PodcastEpisodeModel>> updateEpisode(
      String episodeId, Map<String, dynamic> body);

  /// POST /api/v1/podcast-episodes/{id}/mark-reviewed
  /// Empty body; returns 200 + full updated episode JSON.
  /// Duplicate of IReportsDataSource.markEpisodeReviewed; LSW-DEDUPE-EPISODEOPS
  /// hygiene WO logged to fold both impls when a third caller emerges.
  Future<Either<Failure, PodcastEpisodeModel>> markEpisodeReviewed(
      String episodeId);

  /// POST /api/v1/podcast-episodes/{id}/request-clip
  /// Empty body; returns 200 + full updated episode JSON.
  /// Duplicate of IReportsDataSource.requestEpisodeClip -- see above.
  Future<Either<Failure, PodcastEpisodeModel>> requestEpisodeClip(
      String episodeId);

  // ---------------------------------------------------------------------------
  // Transcripts (LSW-007-B / WO-060) -- added by WO-077 / LSW-015
  // ---------------------------------------------------------------------------

  /// GET /api/v1/podcast-episodes/{id}/transcripts
  Future<Either<Failure, List<PodcastTranscriptModel>>> listTranscripts(
      String episodeId);

  /// POST /api/v1/podcast-episodes/{id}/transcripts -- 201 Created on success.
  Future<Either<Failure, PodcastTranscriptModel>> createTranscript(
      String episodeId, Map<String, dynamic> body);

  /// GET /api/v1/podcast-transcripts/{id}
  Future<Either<Failure, PodcastTranscriptModel>> getTranscript(
      String transcriptId);

  /// PATCH /api/v1/podcast-transcripts/{id}
  Future<Either<Failure, PodcastTranscriptModel>> patchTranscript(
      String transcriptId, Map<String, dynamic> body);

  /// DELETE /api/v1/podcast-transcripts/{id} -- 204 No Content on success.
  Future<Either<Failure, void>> deleteTranscript(String transcriptId);

  /// POST /api/v1/podcast-transcripts/{id}/set-primary
  /// Returns the updated transcript with is_primary=true.
  Future<Either<Failure, PodcastTranscriptModel>> setPrimaryTranscript(
      String transcriptId);

  // ---------------------------------------------------------------------------
  // Headlines (LSW-007-C / WO-061) -- added by WO-077 / LSW-015
  // ---------------------------------------------------------------------------

  /// GET /api/v1/podcast-episodes/{id}/headline-candidates
  Future<Either<Failure, List<PodcastHeadlineCandidateModel>>>
      listHeadlineCandidates(String episodeId);

  /// POST /api/v1/podcast-episodes/{id}/headline-candidates -- 201 on success.
  Future<Either<Failure, PodcastHeadlineCandidateModel>>
      createHeadlineCandidate(String episodeId, Map<String, dynamic> body);

  /// POST /api/v1/podcast-episodes/{id}/generate-headlines -- 202 Accepted.
  /// Fire-and-forget; UI emits HeadlinesGenerating state per Lock #5.
  /// 503 if SQS_HEADLINE_QUEUE_URL unset (HeadlineEnqueuer nil).
  Future<Either<Failure, void>> generateHeadlines(String episodeId);

  /// GET /api/v1/podcast-headline-candidates/{id}
  Future<Either<Failure, PodcastHeadlineCandidateModel>> getHeadlineCandidate(
      String candidateId);

  /// DELETE /api/v1/podcast-headline-candidates/{id}
  Future<Either<Failure, void>> deleteHeadlineCandidate(String candidateId);

  /// POST /api/v1/podcast-headline-candidates/{id}/approve
  /// 200 OK + updated candidate. 409 if "not pending" (already finalized) --
  /// UI auto-refetches list per Pre-Approved Lock #8.
  Future<Either<Failure, PodcastHeadlineCandidateModel>>
      approveHeadlineCandidate(String candidateId);

  // ---------------------------------------------------------------------------
  // Notifications (LSW-007-D / WO-062) -- added by WO-077 / LSW-015
  // ---------------------------------------------------------------------------

  /// GET /api/v1/podcast-episodes/{id}/notifications
  Future<Either<Failure, List<PodcastNotificationModel>>> listNotifications(
      String episodeId);

  /// POST /api/v1/podcast-episodes/{id}/notifications -- 201 Created on success.
  /// Body: channel + recipient + subject + body.
  Future<Either<Failure, PodcastNotificationModel>> createNotification(
      String episodeId, Map<String, dynamic> body);

  /// GET /api/v1/podcast-notifications/{id}
  Future<Either<Failure, PodcastNotificationModel>> getNotification(
      String notificationId);

  /// DELETE /api/v1/podcast-notifications/{id}
  Future<Either<Failure, void>> deleteNotification(String notificationId);

  /// POST /api/v1/podcast-notifications/{id}/send -- 200 OK + updated row.
  /// 503 if provider not configured -- UI surfaces "Notification provider not
  /// configured -- contact infra" toast per Pre-Approved Lock #7.
  Future<Either<Failure, PodcastNotificationModel>> sendNotification(
      String notificationId);
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
                .map((e) =>
                    PodcastPlatformModel.fromJsonDto(e as Map<String, dynamic>))
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
                .map((e) =>
                    PodcastScheduleModel.fromJsonDto(e as Map<String, dynamic>))
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

  // ---------------------------------------------------------------------------
  // Internal helpers (WO-077 / LSW-015) -- mirror the ReportsDataSource style
  // ---------------------------------------------------------------------------

  Future<Either<Failure, T>> _getJsonSingle<T>(
    String endPoint,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      ExceptionHandler<T>(() async {
        final tokenResult = await _auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: endPoint,
              authToken: authToken,
            );
            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }
            final decoded = json.decode(response.body);
            return Right(fromJson(decoded as Map<String, dynamic>));
          },
        );
      }).call();

  Future<Either<Failure, List<T>>> _getJsonList<T>(
    String endPoint,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      ExceptionHandler<List<T>>(() async {
        final tokenResult = await _auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: endPoint,
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
                .map((e) => fromJson(e as Map<String, dynamic>))
                .toList());
          },
        );
      }).call();

  Future<Either<Failure, T>> _postJsonSingle<T>(
    String endPoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? body,
  }) =>
      ExceptionHandler<T>(() async {
        final tokenResult = await _auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.post(
              endPoint: endPoint,
              authToken: authToken,
              body: body,
            );
            if (response.statusCode != HttpStatus.ok &&
                response.statusCode != HttpStatus.created) {
              return Left(HttpFailure.fromResponse(response));
            }
            final decoded = json.decode(response.body);
            return Right(fromJson(decoded as Map<String, dynamic>));
          },
        );
      }).call();

  Future<Either<Failure, T>> _patchJsonSingle<T>(
    String endPoint,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      ExceptionHandler<T>(() async {
        final tokenResult = await _auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.patch(
              endPoint: endPoint,
              authToken: authToken,
              body: body,
            );
            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }
            final decoded = json.decode(response.body);
            return Right(fromJson(decoded as Map<String, dynamic>));
          },
        );
      }).call();

  Future<Either<Failure, void>> _deleteVoid(String endPoint) =>
      ExceptionHandler<void>(() async {
        final tokenResult = await _auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.delete(
              endPoint: endPoint,
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

  Future<Either<Failure, void>> _postVoidWithStatus(
    String endPoint,
    Set<int> acceptedStatusCodes,
  ) =>
      ExceptionHandler<void>(() async {
        final tokenResult = await _auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.post(
              endPoint: endPoint,
              authToken: authToken,
            );
            if (!acceptedStatusCodes.contains(response.statusCode)) {
              return Left(HttpFailure.fromResponse(response));
            }
            return const Right(null);
          },
        );
      }).call();

  // ---------------------------------------------------------------------------
  // Episode operations (LSW-007-A / WO-059) -- WO-077 / LSW-015
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, PodcastEpisodeModel>> updateEpisode(
          String episodeId, Map<String, dynamic> body) =>
      _patchJsonSingle(
        '/api/v1/podcast-episodes/$episodeId',
        body,
        PodcastEpisodeModel.fromJsonDto,
      );

  @override
  Future<Either<Failure, PodcastEpisodeModel>> markEpisodeReviewed(
          String episodeId) =>
      _postJsonSingle(
        '/api/v1/podcast-episodes/$episodeId/mark-reviewed',
        PodcastEpisodeModel.fromJsonDto,
      );

  @override
  Future<Either<Failure, PodcastEpisodeModel>> requestEpisodeClip(
          String episodeId) =>
      _postJsonSingle(
        '/api/v1/podcast-episodes/$episodeId/request-clip',
        PodcastEpisodeModel.fromJsonDto,
      );

  // ---------------------------------------------------------------------------
  // Transcripts (LSW-007-B / WO-060) -- WO-077 / LSW-015
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, List<PodcastTranscriptModel>>> listTranscripts(
          String episodeId) =>
      _getJsonList(
        '/api/v1/podcast-episodes/$episodeId/transcripts',
        PodcastTranscriptModel.fromJsonDto,
      );

  @override
  Future<Either<Failure, PodcastTranscriptModel>> createTranscript(
          String episodeId, Map<String, dynamic> body) =>
      _postJsonSingle(
        '/api/v1/podcast-episodes/$episodeId/transcripts',
        PodcastTranscriptModel.fromJsonDto,
        body: body,
      );

  @override
  Future<Either<Failure, PodcastTranscriptModel>> getTranscript(
          String transcriptId) =>
      _getJsonSingle(
        '/api/v1/podcast-transcripts/$transcriptId',
        PodcastTranscriptModel.fromJsonDto,
      );

  @override
  Future<Either<Failure, PodcastTranscriptModel>> patchTranscript(
          String transcriptId, Map<String, dynamic> body) =>
      _patchJsonSingle(
        '/api/v1/podcast-transcripts/$transcriptId',
        body,
        PodcastTranscriptModel.fromJsonDto,
      );

  @override
  Future<Either<Failure, void>> deleteTranscript(String transcriptId) =>
      _deleteVoid('/api/v1/podcast-transcripts/$transcriptId');

  @override
  Future<Either<Failure, PodcastTranscriptModel>> setPrimaryTranscript(
          String transcriptId) =>
      _postJsonSingle(
        '/api/v1/podcast-transcripts/$transcriptId/set-primary',
        PodcastTranscriptModel.fromJsonDto,
      );

  // ---------------------------------------------------------------------------
  // Headlines (LSW-007-C / WO-061) -- WO-077 / LSW-015
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, List<PodcastHeadlineCandidateModel>>>
      listHeadlineCandidates(String episodeId) => _getJsonList(
            '/api/v1/podcast-episodes/$episodeId/headline-candidates',
            PodcastHeadlineCandidateModel.fromJsonDto,
          );

  @override
  Future<Either<Failure, PodcastHeadlineCandidateModel>>
      createHeadlineCandidate(String episodeId, Map<String, dynamic> body) =>
          _postJsonSingle(
            '/api/v1/podcast-episodes/$episodeId/headline-candidates',
            PodcastHeadlineCandidateModel.fromJsonDto,
            body: body,
          );

  @override
  Future<Either<Failure, void>> generateHeadlines(String episodeId) =>
      _postVoidWithStatus(
        '/api/v1/podcast-episodes/$episodeId/generate-headlines',
        const {HttpStatus.accepted},
      );

  @override
  Future<Either<Failure, PodcastHeadlineCandidateModel>> getHeadlineCandidate(
          String candidateId) =>
      _getJsonSingle(
        '/api/v1/podcast-headline-candidates/$candidateId',
        PodcastHeadlineCandidateModel.fromJsonDto,
      );

  @override
  Future<Either<Failure, void>> deleteHeadlineCandidate(String candidateId) =>
      _deleteVoid('/api/v1/podcast-headline-candidates/$candidateId');

  @override
  Future<Either<Failure, PodcastHeadlineCandidateModel>>
      approveHeadlineCandidate(String candidateId) => _postJsonSingle(
            '/api/v1/podcast-headline-candidates/$candidateId/approve',
            PodcastHeadlineCandidateModel.fromJsonDto,
          );

  // ---------------------------------------------------------------------------
  // Notifications (LSW-007-D / WO-062) -- WO-077 / LSW-015
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, List<PodcastNotificationModel>>> listNotifications(
          String episodeId) =>
      _getJsonList(
        '/api/v1/podcast-episodes/$episodeId/notifications',
        PodcastNotificationModel.fromJsonDto,
      );

  @override
  Future<Either<Failure, PodcastNotificationModel>> createNotification(
          String episodeId, Map<String, dynamic> body) =>
      _postJsonSingle(
        '/api/v1/podcast-episodes/$episodeId/notifications',
        PodcastNotificationModel.fromJsonDto,
        body: body,
      );

  @override
  Future<Either<Failure, PodcastNotificationModel>> getNotification(
          String notificationId) =>
      _getJsonSingle(
        '/api/v1/podcast-notifications/$notificationId',
        PodcastNotificationModel.fromJsonDto,
      );

  @override
  Future<Either<Failure, void>> deleteNotification(String notificationId) =>
      _deleteVoid('/api/v1/podcast-notifications/$notificationId');

  @override
  Future<Either<Failure, PodcastNotificationModel>> sendNotification(
          String notificationId) =>
      _postJsonSingle(
        '/api/v1/podcast-notifications/$notificationId/send',
        PodcastNotificationModel.fromJsonDto,
      );
}
