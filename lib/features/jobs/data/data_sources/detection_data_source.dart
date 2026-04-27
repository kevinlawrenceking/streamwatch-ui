import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../data/providers/rest_client.dart';
import '../../../../data/sources/auth_data_source.dart';
import '../../../../shared/data/http_helpers.dart';
import '../../../../shared/errors/failures/failure.dart';
import '../models/batch_trigger_result.dart';
import '../models/detection_action.dart';
import '../models/detection_run.dart';

const String _pathDetectionRuns = '/api/v1/detection-runs';
const String _pathDetections = '/api/v1/detections';

/// Interface for detection pipeline operations.
///
/// Mirrors `/detection-runs` and `/detections` endpoints per KB
/// section 18g.2. Batch trigger is hard-capped at 50 episodes per
/// section 18g.9; the cap is exposed as [detectionBatchMaxItems] so
/// the UI sources the limit from this contract instead of a magic
/// number.
abstract class IDetectionDataSource {
  /// Per KB section 18g.9 -- batch-trigger accepts up to 50 episodes;
  /// over-cap requests are rejected client-side as toast L-5 before
  /// any HTTP round-trip (saves an obvious 400 BATCH_TOO_LARGE).
  static const int detectionBatchMaxItems = 50;

  Future<Either<Failure, List<DetectionRun>>> listDetectionRuns({
    String? status,
    String? episodeId,
    DateTime? createdFrom,
    DateTime? createdTo,
    int? limit,
    int? offset,
  });

  Future<Either<Failure, DetectionRun>> getDetectionRun(String id);

  /// GET `/api/v1/detection-runs/{id}/actions` -- ordered by
  /// `sequence_index` ASC server-side (KB section 18g.2 amendment 7).
  /// UI renders rows in the order returned without re-sorting.
  Future<Either<Failure, List<DetectionAction>>> listDetectionActions(
    String runId,
  );

  /// POST `/api/v1/detections/trigger`. 202 Accepted with the new
  /// DetectionRun on success (toast L-3-success), 409 ALREADY_ACTIVE
  /// (L-3), 503 SQS_UNCONFIGURED (L-4).
  Future<Either<Failure, DetectionRun>> triggerDetection(String episodeId);

  /// POST `/api/v1/detections/batch-trigger`. Returns a flat list of
  /// per-item results extracted from the 207 Multi-Status envelope.
  ///
  /// Client-side rejection: if `episodeIds.length` exceeds
  /// [detectionBatchMaxItems], returns `Left(ValidationFailure)`
  /// immediately without an HTTP call (toast L-5).
  ///
  /// Outer 503 (enqueuer nil) surfaces as `HttpFailure(statusCode: 503)`
  /// with no per-item results (toast L-7). Per-item statuses are
  /// extracted from the `results` array.
  Future<Either<Failure, List<BatchTriggerItemResult>>> batchTriggerDetection(
    List<String> episodeIds,
  );
}

/// HTTP implementation of [IDetectionDataSource].
class DetectionDataSource implements IDetectionDataSource {
  final IAuthDataSource _auth;
  final IRestClient _client;

  const DetectionDataSource({
    required IAuthDataSource auth,
    required IRestClient client,
  })  : _auth = auth,
        _client = client;

  @override
  Future<Either<Failure, List<DetectionRun>>> listDetectionRuns({
    String? status,
    String? episodeId,
    DateTime? createdFrom,
    DateTime? createdTo,
    int? limit,
    int? offset,
  }) {
    final qp = <String, String>{
      if (status != null) 'status': status,
      if (episodeId != null) 'episode_id': episodeId,
      if (createdFrom != null) 'created_from': createdFrom.toIso8601String(),
      if (createdTo != null) 'created_to': createdTo.toIso8601String(),
      if (limit != null) 'limit': limit.toString(),
      if (offset != null) 'offset': offset.toString(),
    };
    return HttpHelpers.getJsonList(
      auth: _auth,
      client: _client,
      path: _pathDetectionRuns,
      fromJsonDto: DetectionRun.fromJsonDto,
      queryParams: qp.isEmpty ? null : qp,
    );
  }

  @override
  Future<Either<Failure, DetectionRun>> getDetectionRun(String id) =>
      HttpHelpers.getJsonSingle(
        auth: _auth,
        client: _client,
        path: '$_pathDetectionRuns/$id',
        fromJsonDto: DetectionRun.fromJsonDto,
      );

  @override
  Future<Either<Failure, List<DetectionAction>>> listDetectionActions(
    String runId,
  ) =>
      HttpHelpers.getJsonList(
        auth: _auth,
        client: _client,
        path: '$_pathDetectionRuns/$runId/actions',
        fromJsonDto: DetectionAction.fromJsonDto,
      );

  @override
  Future<Either<Failure, DetectionRun>> triggerDetection(String episodeId) =>
      HttpHelpers.postJsonSingle(
        auth: _auth,
        client: _client,
        path: '$_pathDetections/trigger',
        fromJsonDto: DetectionRun.fromJsonDto,
        body: {'episode_id': episodeId},
        // 202 Accepted on success per KB section 18g. The default
        // {200, 201} is overridden so a 200 from a misconfigured
        // server is treated as a failure rather than silent success.
        acceptedStatusCodes: const {HttpStatus.accepted},
      );

  @override
  Future<Either<Failure, List<BatchTriggerItemResult>>> batchTriggerDetection(
    List<String> episodeIds,
  ) async {
    if (episodeIds.length > IDetectionDataSource.detectionBatchMaxItems) {
      // Toast L-5: client-side reject before HTTP. Saves an obvious
      // 400 BATCH_TOO_LARGE round-trip and surfaces a friendlier
      // message that mirrors the locked toast text.
      return const Left(
        ValidationFailure(message: 'Maximum 50 episodes per batch'),
      );
    }
    final result = await HttpHelpers.postJsonSingle<BatchTriggerResponse>(
      auth: _auth,
      client: _client,
      path: '$_pathDetections/batch-trigger',
      fromJsonDto: BatchTriggerResponse.fromJsonDto,
      body: {'episode_ids': episodeIds},
      // 207 Multi-Status only. Both 200 and 202 would indicate a
      // server bug -- reject so the BLoC fold-left handles it as
      // an HttpFailure rather than a malformed-envelope crash.
      acceptedStatusCodes: const {207},
    );
    return result.fold(
      (failure) => Left(failure),
      (envelope) => Right(envelope.results),
    );
  }
}
