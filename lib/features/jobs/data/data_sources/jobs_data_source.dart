import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../data/providers/rest_client.dart';
import '../../../../data/sources/auth_data_source.dart';
import '../../../../shared/data/http_helpers.dart';
import '../../../../shared/errors/failures/failure.dart';
import '../models/podcast_job.dart';

const String _pathJobs = '/api/v1/podcast-jobs';

/// Interface for podcast pipeline jobs operations.
///
/// Mirrors `/podcast-jobs` endpoints per KB section 18g.2.
abstract class IJobsDataSource {
  /// GET `/api/v1/podcast-jobs`. Server returns a raw JSON array.
  Future<Either<Failure, List<PodcastJob>>> listPodcastJobs({
    String? status,
    String? podcastId,
    DateTime? createdFrom,
    DateTime? createdTo,
    int? minRetries,
    int? maxRetries,
    int? limit,
  });

  /// POST `/api/v1/podcast-jobs/{id}/retry`. 202 Accepted on success
  /// per KB section 18g.2 (RFC 7231 -- WO-076 corrective). 200 is
  /// rejected explicitly. 404 surfaces for missing OR non-podcast job
  /// per amendment 2 (no namespace leak); UI shows toast L-2.
  Future<Either<Failure, void>> retryPodcastJob(String jobId);
}

/// HTTP implementation of [IJobsDataSource].
class JobsDataSource implements IJobsDataSource {
  final IAuthDataSource _auth;
  final IRestClient _client;

  const JobsDataSource({
    required IAuthDataSource auth,
    required IRestClient client,
  })  : _auth = auth,
        _client = client;

  @override
  Future<Either<Failure, List<PodcastJob>>> listPodcastJobs({
    String? status,
    String? podcastId,
    DateTime? createdFrom,
    DateTime? createdTo,
    int? minRetries,
    int? maxRetries,
    int? limit,
  }) {
    final qp = <String, String>{
      if (status != null) 'status': status,
      if (podcastId != null) 'podcast_id': podcastId,
      if (createdFrom != null) 'created_from': createdFrom.toIso8601String(),
      if (createdTo != null) 'created_to': createdTo.toIso8601String(),
      if (minRetries != null) 'min_retries': minRetries.toString(),
      if (maxRetries != null) 'max_retries': maxRetries.toString(),
      if (limit != null) 'limit': limit.toString(),
    };
    return HttpHelpers.getJsonList(
      auth: _auth,
      client: _client,
      path: _pathJobs,
      fromJsonDto: PodcastJob.fromJsonDto,
      queryParams: qp.isEmpty ? null : qp,
    );
  }

  @override
  Future<Either<Failure, void>> retryPodcastJob(String jobId) =>
      HttpHelpers.postVoidWithStatus(
        auth: _auth,
        client: _client,
        path: '$_pathJobs/$jobId/retry',
        // 202 ONLY -- 200 is explicitly rejected per WO-078 spec
        // (mirrors KB section 30.7 generateHeadlines pattern).
        acceptedStatusCodes: const {HttpStatus.accepted},
      );
}
