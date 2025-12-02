import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = 'http://localhost:8080'});

  /// Create a job from a URL
  Future<Map<String, dynamic>> createJobFromUrl({
    required String url,
    String? title,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/jobs'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'source': 'url',
        'source_url': url,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create job: ${response.body}');
    }
  }

  /// Create a job from a file upload (supports both web bytes and desktop path)
  Future<Map<String, dynamic>> createJobFromFile({
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    String? title,
    String? description,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/v1/jobs'),
    );

    if (fileBytes != null) {
      // Web: use bytes
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));
    } else if (filePath != null) {
      // Desktop/Mobile: use path
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
    } else {
      throw Exception('Either filePath or fileBytes must be provided');
    }

    if (title != null) request.fields['title'] = title;
    if (description != null) request.fields['description'] = description;

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to upload file: ${response.body}');
    }
  }

  /// Get job details
  Future<Map<String, dynamic>> getJob(String jobId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/jobs/$jobId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get job: ${response.body}');
    }
  }

  /// Get job chunks
  Future<List<dynamic>> getJobChunks(String jobId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/jobs/$jobId/chunks'),
    );

    if (response.statusCode == 200) {
      final body = response.body;
      if (body.isEmpty || body == 'null') {
        return [];
      }
      final decoded = jsonDecode(body);
      return decoded is List ? decoded : [];
    } else {
      throw Exception('Failed to get chunks: ${response.body}');
    }
  }

  /// Get recent jobs
  Future<List<dynamic>> getRecentJobs({int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/jobs?limit=$limit'),
    );

    if (response.statusCode == 200) {
      final body = response.body;
      if (body.isEmpty || body == 'null') {
        return [];
      }
      final decoded = jsonDecode(body);
      return decoded is List ? decoded : [];
    } else {
      throw Exception('Failed to get jobs: ${response.body}');
    }
  }

  /// Get WebSocket URL for job updates
  String getWebSocketUrl(String jobId) {
    final wsBaseUrl = baseUrl.replaceFirst('http', 'ws');
    return '$wsBaseUrl/api/v1/ws/jobs/$jobId';
  }

  /// Get download URL for transcript (cleaned or raw)
  String getTranscriptDownloadUrl(String jobId, {bool cleaned = true}) {
    return '$baseUrl/api/v1/jobs/$jobId/download/transcript?cleaned=$cleaned';
  }

  /// Get download URL for summary
  String getSummaryDownloadUrl(String jobId) {
    return '$baseUrl/api/v1/jobs/$jobId/download/summary';
  }

  /// Get streaming URL for video playback
  String getVideoStreamUrl(String jobId) {
    return '$baseUrl/api/v1/jobs/$jobId/media/stream';
  }

  /// Get thumbnail URL for a job (video-level thumbnail)
  String getJobThumbnailUrl(String jobId) {
    return '$baseUrl/api/v1/jobs/$jobId/thumbnail';
  }

  /// Get thumbnail URL for a segment/chunk
  String getChunkThumbnailUrl(String jobId, String chunkId) {
    return '$baseUrl/api/v1/jobs/$jobId/chunks/$chunkId/thumbnail';
  }
}
