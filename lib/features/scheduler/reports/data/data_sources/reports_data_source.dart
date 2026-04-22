import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../../data/providers/rest_client.dart';
import '../../../../../data/sources/auth_data_source.dart';
import '../../../../../shared/errors/exception_handler.dart';
import '../../../../../shared/errors/failures/failure.dart';
import '../../../../podcasts/data/data_sources/podcast_data_source.dart'
    show PaginatedResponse;
import '../../../../podcasts/data/models/podcast_episode.dart';
import '../models/podcast_schedule_slot.dart';

/// Interface for the WO-065 newsroom reporting endpoints plus the two
/// WO-059 inline action endpoints (mark-reviewed, request-clip) invoked from
/// the episode-valued drill-downs.
///
/// 7 list methods (2 slot-valued + 5 episode-valued) + 2 action methods.
abstract class IReportsDataSource {
  // --- Slot-valued reports (2) -------------------------------------------

  /// GET /api/v1/reports/expected-today
  Future<Either<Failure, PaginatedResponse<PodcastScheduleSlot>>>
      expectedTodayScheduleSlots({int page = 1, int pageSize = 50});

  /// GET /api/v1/reports/late
  /// Dart method name avoids the reserved `late` keyword; the wire slug
  /// remains "late".
  Future<Either<Failure, PaginatedResponse<PodcastScheduleSlot>>>
      lateScheduleSlots({int page = 1, int pageSize = 50});

  // --- Episode-valued reports (5) ----------------------------------------

  /// GET /api/v1/reports/recent
  /// `hours` is optional (server defaults to 24, clamps to [1, 168]).
  Future<Either<Failure, PaginatedResponse<PodcastEpisodeModel>>>
      recentEpisodes({int page = 1, int pageSize = 50, int? hours});

  /// GET /api/v1/reports/transcript-pending
  Future<Either<Failure, PaginatedResponse<PodcastEpisodeModel>>>
      transcriptPendingEpisodes({int page = 1, int pageSize = 50});

  /// GET /api/v1/reports/headline-ready
  Future<Either<Failure, PaginatedResponse<PodcastEpisodeModel>>>
      headlineReadyEpisodes({int page = 1, int pageSize = 50});

  /// GET /api/v1/reports/pending-review
  Future<Either<Failure, PaginatedResponse<PodcastEpisodeModel>>>
      pendingReviewEpisodes({int page = 1, int pageSize = 50});

  /// GET /api/v1/reports/pending-clip-request
  Future<Either<Failure, PaginatedResponse<PodcastEpisodeModel>>>
      pendingClipRequestEpisodes({int page = 1, int pageSize = 50});

  // --- Actions (2) -------------------------------------------------------

  /// POST /api/v1/podcast-episodes/{id}/mark-reviewed
  /// Empty body; 200 returns the full updated PodcastEpisode JSON.
  /// 404 on missing; 409 on backward state transition (not idempotent).
  Future<Either<Failure, PodcastEpisodeModel>> markEpisodeReviewed(
      String episodeId);

  /// POST /api/v1/podcast-episodes/{id}/request-clip
  /// Empty body; 200 returns the full updated PodcastEpisode JSON.
  /// 404 on missing; 409 on backward state transition (not idempotent).
  Future<Either<Failure, PodcastEpisodeModel>> requestEpisodeClip(
      String episodeId);
}

/// HTTP implementation of [IReportsDataSource].
class ReportsDataSource implements IReportsDataSource {
  final IAuthDataSource _auth;
  final IRestClient _client;

  const ReportsDataSource({
    required IAuthDataSource auth,
    required IRestClient client,
  })  : _auth = auth,
        _client = client;

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Runs a GET against `/api/v1/reports/<slug>` and parses the paginated
  /// envelope, reusing the inline parse pattern from podcast_data_source.dart
  /// (listEpisodes). Defensive against the known §18h.9 #4 nil-slice-marshals-
  /// as-null Go behavior.
  Future<Either<Failure, PaginatedResponse<T>>> _listReport<T>({
    required String slug,
    required int page,
    required int pageSize,
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, String> extraQuery = const {},
  }) =>
      ExceptionHandler<PaginatedResponse<T>>(() async {
        final tokenResult = await _auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/reports/$slug',
              authToken: authToken,
              queryParams: {
                'page': page.toString(),
                'page_size': pageSize.toString(),
                ...extraQuery,
              },
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final decoded = json.decode(response.body);
            if (decoded is Map<String, dynamic>) {
              final itemsList = decoded['items'] as List? ?? const [];
              final items = itemsList
                  .map((e) => fromJson(e as Map<String, dynamic>))
                  .toList();
              return Right(PaginatedResponse<T>(
                items: items,
                total: decoded['total'] as int? ?? items.length,
                page: decoded['page'] as int? ?? page,
                pageSize: decoded['page_size'] as int? ?? pageSize,
              ));
            }

            if (decoded is List) {
              final items =
                  decoded.map((e) => fromJson(e as Map<String, dynamic>)).toList();
              return Right(PaginatedResponse<T>(
                items: items,
                total: items.length,
                page: 1,
                pageSize: items.length,
              ));
            }

            return Right(PaginatedResponse<T>(
              items: const [],
              total: 0,
              page: page,
              pageSize: pageSize,
            ));
          },
        );
      }).call();

  Future<Either<Failure, PodcastEpisodeModel>> _postEpisodeAction(
    String episodeId,
    String action,
  ) =>
      ExceptionHandler<PodcastEpisodeModel>(() async {
        final tokenResult = await _auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.post(
              endPoint: '/api/v1/podcast-episodes/$episodeId/$action',
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
  // Slot-valued
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, PaginatedResponse<PodcastScheduleSlot>>>
      expectedTodayScheduleSlots({int page = 1, int pageSize = 50}) {
    return _listReport<PodcastScheduleSlot>(
      slug: 'expected-today',
      page: page,
      pageSize: pageSize,
      fromJson: PodcastScheduleSlot.fromJsonDto,
    );
  }

  @override
  Future<Either<Failure, PaginatedResponse<PodcastScheduleSlot>>>
      lateScheduleSlots({int page = 1, int pageSize = 50}) {
    return _listReport<PodcastScheduleSlot>(
      slug: 'late',
      page: page,
      pageSize: pageSize,
      fromJson: PodcastScheduleSlot.fromJsonDto,
    );
  }

  // ---------------------------------------------------------------------------
  // Episode-valued
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, PaginatedResponse<PodcastEpisodeModel>>> recentEpisodes(
      {int page = 1, int pageSize = 50, int? hours}) {
    return _listReport<PodcastEpisodeModel>(
      slug: 'recent',
      page: page,
      pageSize: pageSize,
      fromJson: PodcastEpisodeModel.fromJsonDto,
      extraQuery: hours != null ? {'hours': hours.toString()} : const {},
    );
  }

  @override
  Future<Either<Failure, PaginatedResponse<PodcastEpisodeModel>>>
      transcriptPendingEpisodes({int page = 1, int pageSize = 50}) {
    return _listReport<PodcastEpisodeModel>(
      slug: 'transcript-pending',
      page: page,
      pageSize: pageSize,
      fromJson: PodcastEpisodeModel.fromJsonDto,
    );
  }

  @override
  Future<Either<Failure, PaginatedResponse<PodcastEpisodeModel>>>
      headlineReadyEpisodes({int page = 1, int pageSize = 50}) {
    return _listReport<PodcastEpisodeModel>(
      slug: 'headline-ready',
      page: page,
      pageSize: pageSize,
      fromJson: PodcastEpisodeModel.fromJsonDto,
    );
  }

  @override
  Future<Either<Failure, PaginatedResponse<PodcastEpisodeModel>>>
      pendingReviewEpisodes({int page = 1, int pageSize = 50}) {
    return _listReport<PodcastEpisodeModel>(
      slug: 'pending-review',
      page: page,
      pageSize: pageSize,
      fromJson: PodcastEpisodeModel.fromJsonDto,
    );
  }

  @override
  Future<Either<Failure, PaginatedResponse<PodcastEpisodeModel>>>
      pendingClipRequestEpisodes({int page = 1, int pageSize = 50}) {
    return _listReport<PodcastEpisodeModel>(
      slug: 'pending-clip-request',
      page: page,
      pageSize: pageSize,
      fromJson: PodcastEpisodeModel.fromJsonDto,
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, PodcastEpisodeModel>> markEpisodeReviewed(
          String episodeId) =>
      _postEpisodeAction(episodeId, 'mark-reviewed');

  @override
  Future<Either<Failure, PodcastEpisodeModel>> requestEpisodeClip(
          String episodeId) =>
      _postEpisodeAction(episodeId, 'request-clip');
}
