import 'dart:convert';
import 'package:http/http.dart' as http;

/// Interface for REST client operations.
/// Allows for easy mocking in tests.
abstract class IRestClient {
  /// Performs a GET request.
  Future<http.Response> get({
    required String endPoint,
    String? authToken,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  });

  /// Performs a POST request with JSON body.
  Future<http.Response> post({
    required String endPoint,
    String? authToken,
    Map<String, String>? headers,
    Object? body,
  });

  /// Performs a PUT request with JSON body.
  Future<http.Response> put({
    required String endPoint,
    String? authToken,
    Map<String, String>? headers,
    Object? body,
  });

  /// Performs a PATCH request with JSON body.
  Future<http.Response> patch({
    required String endPoint,
    String? authToken,
    Map<String, String>? headers,
    Object? body,
  });

  /// Performs a DELETE request.
  Future<http.Response> delete({
    required String endPoint,
    String? authToken,
    Map<String, String>? headers,
  });

  /// Sends a multipart request for file uploads.
  Future<http.StreamedResponse> sendMultipart({
    required http.MultipartRequest request,
  });

  /// The base URL for all requests.
  String get baseUrl;
}

/// Implementation of [IRestClient] using the http package.
class RestClient implements IRestClient {
  @override
  final String baseUrl;
  final http.Client _client;

  RestClient({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> _buildHeaders({
    String? authToken,
    Map<String, String>? additionalHeaders,
    bool isJson = true,
  }) {
    final headers = <String, String>{
      if (isJson) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authToken != null && authToken.isNotEmpty)
        'Authorization': 'Bearer $authToken',
      ...?additionalHeaders,
    };
    return headers;
  }

  Uri _buildUri(String endPoint, Map<String, String>? queryParams) {
    final uri = Uri.parse('$baseUrl$endPoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  @override
  Future<http.Response> get({
    required String endPoint,
    String? authToken,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endPoint, queryParams);
    final requestHeaders = _buildHeaders(
      authToken: authToken,
      additionalHeaders: headers,
      isJson: false,
    );
    return await _client.get(uri, headers: requestHeaders);
  }

  @override
  Future<http.Response> post({
    required String endPoint,
    String? authToken,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = _buildUri(endPoint, null);
    final requestHeaders = _buildHeaders(
      authToken: authToken,
      additionalHeaders: headers,
    );
    final encodedBody = body != null ? json.encode(body) : null;
    return await _client.post(uri, headers: requestHeaders, body: encodedBody);
  }

  @override
  Future<http.Response> put({
    required String endPoint,
    String? authToken,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = _buildUri(endPoint, null);
    final requestHeaders = _buildHeaders(
      authToken: authToken,
      additionalHeaders: headers,
    );
    final encodedBody = body != null ? json.encode(body) : null;
    return await _client.put(uri, headers: requestHeaders, body: encodedBody);
  }

  @override
  Future<http.Response> patch({
    required String endPoint,
    String? authToken,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = _buildUri(endPoint, null);
    final requestHeaders = _buildHeaders(
      authToken: authToken,
      additionalHeaders: headers,
    );
    final encodedBody = body != null ? json.encode(body) : null;
    return await _client.patch(uri, headers: requestHeaders, body: encodedBody);
  }

  @override
  Future<http.Response> delete({
    required String endPoint,
    String? authToken,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endPoint, null);
    final requestHeaders = _buildHeaders(
      authToken: authToken,
      additionalHeaders: headers,
      isJson: false,
    );
    return await _client.delete(uri, headers: requestHeaders);
  }

  @override
  Future<http.StreamedResponse> sendMultipart({
    required http.MultipartRequest request,
  }) async {
    return await request.send();
  }

  /// Closes the underlying HTTP client.
  void close() {
    _client.close();
  }
}
