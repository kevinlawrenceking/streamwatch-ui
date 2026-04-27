import 'package:dartz/dartz.dart';

import '../../../../data/providers/rest_client.dart';
import '../../../../data/sources/auth_data_source.dart';
import '../../../../shared/data/http_helpers.dart';
import '../../../../shared/errors/failures/failure.dart';
import '../models/change_status_request.dart';
import '../models/guest_watchlist_entry.dart';
import '../models/patch_guest_watchlist_request.dart';

const String _pathWatchlist = '/api/v1/podcast-guest-watchlist';

/// Interface for guest watchlist editorial-tracking operations.
///
/// Mirrors the 5 admin-gated endpoints under `/podcast-guest-watchlist`
/// per KB section 18f.3. Two-sink terminal state machine; `active` is
/// the only non-terminal state.
abstract class IGuestWatchlistDataSource {
  /// GET `/api/v1/podcast-guest-watchlist`. Returns a flat list (the API
  /// returns a raw JSON array per `RespondWithJSON(w, 200, entries)`).
  /// Caller scopes the result by passing optional filter args.
  Future<Either<Failure, List<PodcastGuestWatchlistEntry>>>
      listGuestWatchlistEntries({
    String? status,
    int? limit,
    int? offset,
  });

  /// POST `/api/v1/podcast-guest-watchlist`. Server forces `status='active'`
  /// and populates `created_by` from the auth context per KB section 18f.8.
  Future<Either<Failure, PodcastGuestWatchlistEntry>> createGuestWatchlistEntry(
    Map<String, dynamic> body,
  );

  /// GET `/api/v1/podcast-guest-watchlist/{id}`. 404 surfaces as
  /// `HttpFailure(statusCode: 404)`.
  Future<Either<Failure, PodcastGuestWatchlistEntry>> getGuestWatchlistEntry(
    String id,
  );

  /// PATCH `/api/v1/podcast-guest-watchlist/{id}` with the 4-field
  /// allowlist enforced by [PatchGuestWatchlistEntryRequest.toJsonDto].
  /// Server rejects forbidden fields (status / matched_episode_id /
  /// matched_at / expires_at) with 400 + field name (toast L-10).
  Future<Either<Failure, PodcastGuestWatchlistEntry>> patchGuestWatchlistEntry(
    String id,
    PatchGuestWatchlistEntryRequest request,
  );

  /// POST `/api/v1/podcast-guest-watchlist/{id}/change-status`.
  /// 400 surfaces as L-8, 409 surfaces as L-9 in WO-078 KB section 31.12.
  Future<Either<Failure, PodcastGuestWatchlistEntry>>
      changeGuestWatchlistEntryStatus(
    String id,
    ChangeWatchlistStatusRequest request,
  );
}

/// HTTP implementation of [IGuestWatchlistDataSource].
class GuestWatchlistDataSource implements IGuestWatchlistDataSource {
  final IAuthDataSource _auth;
  final IRestClient _client;

  const GuestWatchlistDataSource({
    required IAuthDataSource auth,
    required IRestClient client,
  })  : _auth = auth,
        _client = client;

  @override
  Future<Either<Failure, List<PodcastGuestWatchlistEntry>>>
      listGuestWatchlistEntries({
    String? status,
    int? limit,
    int? offset,
  }) {
    final qp = <String, String>{
      if (status != null) 'status': status,
      if (limit != null) 'limit': limit.toString(),
      if (offset != null) 'offset': offset.toString(),
    };
    return HttpHelpers.getJsonList(
      auth: _auth,
      client: _client,
      path: _pathWatchlist,
      fromJsonDto: PodcastGuestWatchlistEntry.fromJsonDto,
      queryParams: qp.isEmpty ? null : qp,
    );
  }

  @override
  Future<Either<Failure, PodcastGuestWatchlistEntry>> createGuestWatchlistEntry(
    Map<String, dynamic> body,
  ) =>
      HttpHelpers.postJsonSingle(
        auth: _auth,
        client: _client,
        path: _pathWatchlist,
        fromJsonDto: PodcastGuestWatchlistEntry.fromJsonDto,
        body: body,
      );

  @override
  Future<Either<Failure, PodcastGuestWatchlistEntry>> getGuestWatchlistEntry(
    String id,
  ) =>
      HttpHelpers.getJsonSingle(
        auth: _auth,
        client: _client,
        path: '$_pathWatchlist/$id',
        fromJsonDto: PodcastGuestWatchlistEntry.fromJsonDto,
      );

  @override
  Future<Either<Failure, PodcastGuestWatchlistEntry>> patchGuestWatchlistEntry(
    String id,
    PatchGuestWatchlistEntryRequest request,
  ) =>
      HttpHelpers.patchJsonSingle(
        auth: _auth,
        client: _client,
        path: '$_pathWatchlist/$id',
        body: request.toJsonDto(),
        fromJsonDto: PodcastGuestWatchlistEntry.fromJsonDto,
      );

  @override
  Future<Either<Failure, PodcastGuestWatchlistEntry>>
      changeGuestWatchlistEntryStatus(
    String id,
    ChangeWatchlistStatusRequest request,
  ) =>
          HttpHelpers.postJsonSingle(
            auth: _auth,
            client: _client,
            path: '$_pathWatchlist/$id/change-status',
            fromJsonDto: PodcastGuestWatchlistEntry.fromJsonDto,
            body: request.toJsonDto(),
          );
}
