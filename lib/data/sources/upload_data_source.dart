import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import '../models/job_model.dart';
import '../../shared/errors/exception_handler.dart';
import '../../shared/errors/failures/failure.dart';
import '../../utils/config.dart';
import 'auth_data_source.dart';

/// Model for presigned upload response from API.
class PresignedUploadResponse {
  final String uploadId;
  final String bucket;
  final String key;
  final String url;
  final Map<String, String> headers;
  final DateTime expiresAt;
  final int expiresIn;

  PresignedUploadResponse({
    required this.uploadId,
    required this.bucket,
    required this.key,
    required this.url,
    required this.headers,
    required this.expiresAt,
    required this.expiresIn,
  });

  factory PresignedUploadResponse.fromJson(Map<String, dynamic> json) {
    final headersRaw = json['headers'] as Map<String, dynamic>? ?? {};
    final headers = headersRaw.map((k, v) => MapEntry(k, v.toString()));

    return PresignedUploadResponse(
      uploadId: json['upload_id'] as String,
      bucket: json['bucket'] as String,
      key: json['key'] as String,
      url: json['url'] as String,
      headers: headers,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      expiresIn: json['expires_in'] as int,
    );
  }
}

/// Model for upload completion response from API.
class UploadCompleteResponse {
  final String uploadId;
  final String jobId;
  final String status;
  final String bucket;
  final String key;
  final String contentType;
  final int bytes;

  UploadCompleteResponse({
    required this.uploadId,
    required this.jobId,
    required this.status,
    required this.bucket,
    required this.key,
    required this.contentType,
    required this.bytes,
  });

  factory UploadCompleteResponse.fromJson(Map<String, dynamic> json) {
    return UploadCompleteResponse(
      uploadId: json['upload_id'] as String,
      jobId: json['job_id'] as String,
      status: json['status'] as String,
      bucket: json['bucket'] as String,
      key: json['key'] as String,
      contentType: json['content_type'] as String,
      bytes: json['bytes'] as int,
    );
  }
}

/// Callback for upload progress updates.
typedef UploadProgressCallback = void Function(int bytesSent, int totalBytes);

/// Interface for presigned S3 upload operations.
abstract class IUploadDataSource {
  /// Step 1: Request a presigned URL for uploading a file.
  Future<Either<Failure, PresignedUploadResponse>> requestPresignedUrl({
    required String filename,
    required String contentType,
    required int bytes,
    String? title,
    String? description,
    String? celebrities, // Comma/newline separated celebrity names
    String? transcriptionEngine,
    int? segmentDuration,
  });

  /// Step 2: Upload file bytes directly to S3 using the presigned URL.
  Future<Either<Failure, void>> uploadToS3({
    required String presignedUrl,
    required Map<String, String> headers,
    required Uint8List fileBytes,
    UploadProgressCallback? onProgress,
  });

  /// Step 3: Complete the upload and create a job.
  Future<Either<Failure, JobModel>> completeUpload({
    required String uploadId,
    String? etag,
  });
}

/// Implementation of [IUploadDataSource] using REST API and S3.
class UploadDataSource implements IUploadDataSource {
  final String _baseUrl;
  final http.Client? _httpClient;
  final IAuthDataSource _auth;

  UploadDataSource({
    required IAuthDataSource auth,
    String? baseUrl,
    http.Client? httpClient,
  })  : _auth = auth,
        _baseUrl = baseUrl ?? Config.instance.apiBaseUrl,
        _httpClient = httpClient;

  http.Client get _client => _httpClient ?? http.Client();

  Future<Map<String, String>> _authHeaders({bool isJson = true}) async {
    final headers = <String, String>{
      if (isJson) 'Content-Type': 'application/json',
    };
    final tokenResult = await _auth.getAuthToken();
    tokenResult.fold((_) {}, (token) {
      if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    });
    return headers;
  }

  @override
  Future<Either<Failure, PresignedUploadResponse>> requestPresignedUrl({
    required String filename,
    required String contentType,
    required int bytes,
    String? title,
    String? description,
    String? celebrities,
    String? transcriptionEngine,
    int? segmentDuration,
  }) =>
      ExceptionHandler<PresignedUploadResponse>(() async {
        final body = <String, dynamic>{
          'filename': filename,
          'content_type': contentType,
          'bytes': bytes,
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (celebrities != null) 'celebrities_manual': celebrities,
          if (transcriptionEngine != null)
            'transcription_engine': transcriptionEngine,
          if (segmentDuration != null) 'segment_duration': segmentDuration,
        };

        // Log request (no secrets)
        print('[UploadDataSource] Requesting presigned URL for: $filename ($bytes bytes)');

        final response = await _client.post(
          Uri.parse('$_baseUrl/api/v1/uploads/presign'),
          headers: await _authHeaders(),
          body: json.encode(body),
        );

        // Log response status (no URL which contains signature)
        print('[UploadDataSource] Presign response: ${response.statusCode}');

        if (response.statusCode != HttpStatus.ok &&
            response.statusCode != HttpStatus.created) {
          return Left(HttpFailure.fromResponse(response));
        }

        final data = json.decode(response.body) as Map<String, dynamic>;
        // Log upload_id for debugging (safe to log)
        print('[UploadDataSource] Upload ID: ${data['upload_id']}');

        return Right(PresignedUploadResponse.fromJson(data));
      })();

  @override
  Future<Either<Failure, void>> uploadToS3({
    required String presignedUrl,
    required Map<String, String> headers,
    required Uint8List fileBytes,
    UploadProgressCallback? onProgress,
  }) =>
      ExceptionHandler<void>(() async {
        // Log upload start (URL is NOT logged - contains signature)
        print('[UploadDataSource] Starting S3 upload: ${fileBytes.length} bytes');

        try {
          // Create request
          final request = http.Request('PUT', Uri.parse(presignedUrl));

          // Set headers from presigned response, excluding forbidden headers
          // Browsers cannot set Host header - it's automatically derived from URL
          final filteredHeaders = Map<String, String>.from(headers)
            ..remove('Host')
            ..remove('host');
          request.headers.addAll(filteredHeaders);

          // Set Content-Length explicitly
          request.headers['Content-Length'] = fileBytes.length.toString();

          // Set body
          request.bodyBytes = fileBytes;

          // Send the request
          final streamedResponse = await _client.send(request);

          // Get response
          final response = await http.Response.fromStream(streamedResponse);

          print('[UploadDataSource] S3 upload response: ${response.statusCode}');

          if (response.statusCode != HttpStatus.ok &&
              response.statusCode != 200) {
            // Log error details for debugging
            print('[UploadDataSource] S3 error body: ${response.body}');
            return Left(HttpFailure(
              statusCode: response.statusCode,
              message: 'S3 upload failed: ${response.statusCode}',
            ));
          }

          print('[UploadDataSource] S3 upload completed successfully');
          return const Right(null);
        } catch (e) {
          print('[UploadDataSource] S3 upload exception: $e');
          return Left(NetworkFailure('S3 upload failed: $e'));
        }
      })();

  @override
  Future<Either<Failure, JobModel>> completeUpload({
    required String uploadId,
    String? etag,
  }) =>
      ExceptionHandler<JobModel>(() async {
        final body = <String, dynamic>{
          'upload_id': uploadId,
          if (etag != null) 'etag': etag,
        };

        print('[UploadDataSource] Completing upload: $uploadId');

        final response = await _client.post(
          Uri.parse('$_baseUrl/api/v1/uploads/complete'),
          headers: await _authHeaders(),
          body: json.encode(body),
        );

        print('[UploadDataSource] Complete response: ${response.statusCode}');

        if (response.statusCode != HttpStatus.ok &&
            response.statusCode != HttpStatus.created) {
          return Left(HttpFailure.fromResponse(response));
        }

        final data = json.decode(response.body) as Map<String, dynamic>;
        final jobId = data['job_id'] as String;

        print('[UploadDataSource] Job created: $jobId');

        // Fetch the full job model
        final jobResponse = await _client.get(
          Uri.parse('$_baseUrl/api/v1/jobs/$jobId'),
          headers: await _authHeaders(),
        );

        if (jobResponse.statusCode != HttpStatus.ok) {
          // Still return success with minimal job data from complete response
          return Right(JobModel(
            jobId: jobId,
            status: 'queued',
            source: 'upload',
            filename: data['key']?.toString().split('/').last,
            createdAt: DateTime.now(),
            progressPct: 0,
            completedChunks: 0,
          ));
        }

        final jobData = json.decode(jobResponse.body) as Map<String, dynamic>;
        // GetJob returns {job: {...}}, so unwrap the job object
        final jobObject = jobData['job'] as Map<String, dynamic>? ?? jobData;
        return Right(JobModel.fromJsonDto(jobObject));
      })();
}
