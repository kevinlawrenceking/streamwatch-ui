import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import '../models/job_model.dart';
import '../models/chunk_model.dart';
import '../models/celebrity_model.dart';
import '../providers/rest_client.dart';
import 'auth_data_source.dart';
import '../../shared/errors/exception_handler.dart';
import '../../shared/errors/failures/failure.dart';
import '../../utils/config.dart';

/// Interface for job-related data operations.
abstract class IJobDataSource {
  /// Creates a job from a URL (YouTube, Twitter, etc.).
  Future<Either<Failure, JobModel>> createJobFromUrl({
    required String url,
    String? title,
    String? description,
    String? transcriptionEngine,
    int? segmentDuration, // Chunk duration in seconds: 60, 180, 300, 600, 900, 1800, 3600
    bool isLive = false, // Whether this is a live stream capture
    int? captureSeconds, // Duration to capture from live stream (60-3600)
  });

  /// Creates a job from a file upload.
  Future<Either<Failure, JobModel>> createJobFromFile({
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    String? title,
    String? description,
    String? transcriptionEngine,
    int? segmentDuration, // Chunk duration in seconds: 60, 180, 300, 600, 900, 1800, 3600
  });

  /// Gets a job by ID.
  Future<Either<Failure, JobModel>> getJob(String jobId);

  /// Gets a job by ID along with celebrities identified in the video.
  /// Returns a named record with {job, celebrities} for type safety.
  Future<Either<Failure, ({JobModel job, List<CelebrityModel> celebrities})>>
      getJobWithCelebrities(String jobId);

  /// Gets chunks for a job.
  Future<Either<Failure, List<ChunkModel>>> getJobChunks(String jobId);

  /// Gets recent jobs.
  Future<Either<Failure, List<JobModel>>> getRecentJobs({int limit = 20});

  /// Gets the worker log file for a job.
  Future<Either<Failure, String>> getJobLog(String jobId, {int? tailLines});

  /// Updates the flag status of a job.
  Future<Either<Failure, JobModel>> updateJobFlag({
    required String jobId,
    required bool isFlagged,
    String? flagNote,
  });

  /// Requests a job to pause processing.
  Future<Either<Failure, JobModel>> pauseJob(String jobId);

  /// Resumes a paused job.
  Future<Either<Failure, JobModel>> resumeJob(String jobId);

  /// Soft deletes a job.
  Future<Either<Failure, void>> deleteJob(String jobId);

  // URL generators (no auth needed - these just build URLs)
  String getWebSocketUrl(String jobId);
  String getVideoStreamUrl(String jobId);
  String getTranscriptDownloadUrl(String jobId, {bool cleaned = true});
  String getSummaryDownloadUrl(String jobId);
  String getJobThumbnailUrl(String jobId);
  String getChunkThumbnailUrl(String jobId, String chunkId);
}

/// Implementation of [IJobDataSource] using REST API.
class JobDataSource implements IJobDataSource {
  final IAuthDataSource _auth;
  final IRestClient _client;
  final String _baseUrl;

  JobDataSource({
    required IAuthDataSource auth,
    required IRestClient client,
    String? baseUrl,
  })  : _auth = auth,
        _client = client,
        _baseUrl = baseUrl ?? Config.instance.apiBaseUrl;

  @override
  Future<Either<Failure, JobModel>> createJobFromUrl({
    required String url,
    String? title,
    String? description,
    String? transcriptionEngine,
    int? segmentDuration,
    bool isLive = false,
    int? captureSeconds,
  }) =>
      ExceptionHandler<JobModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            // Use direct http.post like the original working code
            // This bypasses RestClient to match the pattern of createJobFromFile
            final headers = <String, String>{
              'Content-Type': 'application/json',
              if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
            };

            final body = <String, dynamic>{
              'source': 'url',
              'source_url': url,
              if (title != null) 'title': title,
              if (description != null) 'description': description,
              if (transcriptionEngine != null)
                'transcription_engine': transcriptionEngine,
              if (segmentDuration != null)
                'segment_duration': segmentDuration,
            };

            // Add live stream capture fields
            if (isLive) {
              body['is_live'] = true;
              if (captureSeconds != null) {
                body['capture_seconds'] = captureSeconds;
              }
            }

            final response = await http.post(
              Uri.parse('$_baseUrl/api/v1/jobs'),
              headers: headers,
              body: json.encode(body),
            );

            if (response.statusCode != HttpStatus.ok &&
                response.statusCode != HttpStatus.created) {
              return Left(HttpFailure.fromResponse(response));
            }

            final data = json.decode(response.body);
            return Right(JobModel.fromJsonDto(data));
          },
        );
      })();

  @override
  Future<Either<Failure, JobModel>> createJobFromFile({
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    String? title,
    String? description,
    String? transcriptionEngine,
    int? segmentDuration,
  }) =>
      ExceptionHandler<JobModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final request = http.MultipartRequest(
              'POST',
              Uri.parse('$_baseUrl/api/v1/jobs'),
            );

            // Add auth header
            if (authToken.isNotEmpty) {
              request.headers['Authorization'] = 'Bearer $authToken';
            }

            // Add file
            if (fileBytes != null) {
              request.files.add(http.MultipartFile.fromBytes(
                'file',
                fileBytes,
                filename: fileName,
              ));
            } else if (filePath != null) {
              request.files
                  .add(await http.MultipartFile.fromPath('file', filePath));
            } else {
              return const Left(
                  ValidationFailure(message: 'Either filePath or fileBytes must be provided'));
            }

            // Add fields
            if (title != null) request.fields['title'] = title;
            if (description != null) request.fields['description'] = description;
            if (transcriptionEngine != null) {
              request.fields['transcription_engine'] = transcriptionEngine;
            }
            if (segmentDuration != null) {
              request.fields['segment_duration'] = segmentDuration.toString();
            }

            final streamedResponse = await _client.sendMultipart(request: request);
            final response = await http.Response.fromStream(streamedResponse);

            if (response.statusCode != HttpStatus.ok &&
                response.statusCode != HttpStatus.created) {
              return Left(HttpFailure.fromResponse(response));
            }

            final data = json.decode(response.body);
            return Right(JobModel.fromJsonDto(data));
          },
        );
      })();

  @override
  Future<Either<Failure, JobModel>> getJob(String jobId) =>
      ExceptionHandler<JobModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/jobs/$jobId',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final data = json.decode(response.body) as Map<String, dynamic>;
            // GetJob returns {job: {...}, celebrities: [...]}, so unwrap the job object
            final jobObject = data['job'] as Map<String, dynamic>? ?? data;
            return Right(JobModel.fromJsonDto(jobObject));
          },
        );
      })();

  @override
  Future<Either<Failure, ({JobModel job, List<CelebrityModel> celebrities})>>
      getJobWithCelebrities(String jobId) =>
      ExceptionHandler<({JobModel job, List<CelebrityModel> celebrities})>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/jobs/$jobId',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final data = json.decode(response.body) as Map<String, dynamic>;
            final jobObject = data['job'] as Map<String, dynamic>? ?? data;
            final job = JobModel.fromJsonDto(jobObject);

            // Parse celebrities defensively - empty list if missing/invalid
            final celebrities = parseCelebrities(data['celebrities']);

            // Stable sort: confidence desc (null last), then by name for ties
            celebrities.sort((a, b) {
              // Null confidence goes last
              if (a.confidence == null && b.confidence == null) {
                return a.name.compareTo(b.name); // alphabetical for nulls
              }
              if (a.confidence == null) return 1; // a goes after b
              if (b.confidence == null) return -1; // b goes after a
              // Both have confidence: desc order, name as tiebreaker
              final confCompare = b.confidence!.compareTo(a.confidence!);
              if (confCompare != 0) return confCompare;
              return a.name.compareTo(b.name);
            });

            return Right((job: job, celebrities: celebrities));
          },
        );
      })();

  @override
  Future<Either<Failure, List<ChunkModel>>> getJobChunks(String jobId) =>
      ExceptionHandler<List<ChunkModel>>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/jobs/$jobId/chunks',
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

            final chunks =
                decoded.map((c) => ChunkModel.fromJsonDto(c)).toList();
            return Right(chunks);
          },
        );
      })();

  @override
  Future<Either<Failure, List<JobModel>>> getRecentJobs({int limit = 20}) =>
      ExceptionHandler<List<JobModel>>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/jobs',
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

            final jobs = decoded.map((j) => JobModel.fromJsonDto(j)).toList();
            return Right(jobs);
          },
        );
      })();

  @override
  Future<Either<Failure, String>> getJobLog(String jobId, {int? tailLines}) =>
      ExceptionHandler<String>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final queryParams = <String, String>{};
            if (tailLines != null) {
              queryParams['tail'] = tailLines.toString();
            }

            final response = await _client.get(
              endPoint: '/api/v1/jobs/$jobId/log',
              authToken: authToken,
              queryParams: queryParams.isNotEmpty ? queryParams : null,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            return Right(response.body);
          },
        );
      })();

  @override
  Future<Either<Failure, JobModel>> updateJobFlag({
    required String jobId,
    required bool isFlagged,
    String? flagNote,
  }) =>
      ExceptionHandler<JobModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final body = <String, dynamic>{
              'is_flagged': isFlagged,
              if (flagNote != null) 'flag_note': flagNote,
            };

            final response = await _client.patch(
              endPoint: '/api/v1/jobs/$jobId/flag',
              authToken: authToken,
              body: body,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final data = json.decode(response.body) as Map<String, dynamic>;
            final jobObject = data['job'] as Map<String, dynamic>? ?? data;
            return Right(JobModel.fromJsonDto(jobObject));
          },
        );
      })();

  @override
  Future<Either<Failure, JobModel>> pauseJob(String jobId) =>
      ExceptionHandler<JobModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.post(
              endPoint: '/api/v1/jobs/$jobId/pause',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final data = json.decode(response.body) as Map<String, dynamic>;
            final jobObject = data['job'] as Map<String, dynamic>? ?? data;
            return Right(JobModel.fromJsonDto(jobObject));
          },
        );
      })();

  @override
  Future<Either<Failure, JobModel>> resumeJob(String jobId) =>
      ExceptionHandler<JobModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.post(
              endPoint: '/api/v1/jobs/$jobId/resume',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final data = json.decode(response.body) as Map<String, dynamic>;
            final jobObject = data['job'] as Map<String, dynamic>? ?? data;
            return Right(JobModel.fromJsonDto(jobObject));
          },
        );
      })();

  @override
  Future<Either<Failure, void>> deleteJob(String jobId) =>
      ExceptionHandler<void>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.delete(
              endPoint: '/api/v1/jobs/$jobId',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok &&
                response.statusCode != HttpStatus.noContent) {
              return Left(HttpFailure.fromResponse(response));
            }

            return const Right(null);
          },
        );
      })();

  // URL generators
  @override
  String getWebSocketUrl(String jobId) {
    return '${_baseUrl.replaceFirst('http', 'ws')}/api/v1/ws/jobs/$jobId';
  }

  @override
  String getVideoStreamUrl(String jobId) {
    return '$_baseUrl/api/v1/jobs/$jobId/media/stream';
  }

  @override
  String getTranscriptDownloadUrl(String jobId, {bool cleaned = true}) {
    return '$_baseUrl/api/v1/jobs/$jobId/download/transcript?cleaned=$cleaned';
  }

  @override
  String getSummaryDownloadUrl(String jobId) {
    return '$_baseUrl/api/v1/jobs/$jobId/download/summary';
  }

  @override
  String getJobThumbnailUrl(String jobId) {
    return '$_baseUrl/api/v1/jobs/$jobId/thumbnail';
  }

  @override
  String getChunkThumbnailUrl(String jobId, String chunkId) {
    return '$_baseUrl/api/v1/jobs/$jobId/chunks/$chunkId/thumbnail';
  }
}
