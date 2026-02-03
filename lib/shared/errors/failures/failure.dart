import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;

/// Base class for all failures in the application.
/// Uses Equatable for value equality comparison.
class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

/// Failure related to authentication issues.
class AuthFailure extends Failure {
  const AuthFailure([String message = 'Authentication failed']) : super(message);
}

/// Failure when the user's session has expired.
class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([String message = 'Session expired, please login again'])
      : super(message);
}

/// General failure for unexpected errors.
class GeneralFailure extends Failure {
  const GeneralFailure([String message = 'An unexpected error occurred']) : super(message);
}

/// Failure for network connectivity issues.
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network connection failed']) : super(message);
}

/// Failure for HTTP errors with status code.
class HttpFailure extends Failure {
  final int statusCode;

  const HttpFailure({
    required this.statusCode,
    required String message,
  }) : super(message);

  @override
  List<Object?> get props => [statusCode, message];

  /// Creates an HttpFailure from an HTTP response.
  /// Attempts to parse error details from the response body.
  static Failure fromResponse(http.Response response) {
    try {
      if (response.body.isNotEmpty) {
        final decoded = json.decode(response.body);
        // Handle both Map responses and string error messages
        if (decoded is Map<String, dynamic>) {
          final errorField = decoded['error'];
          // API returns {"error": "message string"} for simple errors
          if (errorField is String) {
            return HttpFailure(
              statusCode: response.statusCode,
              message: errorField,
            );
          }
          // API returns {"error": {"code": "...", "message": "..."}} for structured errors
          if (errorField is Map<String, dynamic>) {
            final apiError = ApiError.fromJsonDto(errorField);
            if (apiError != null) {
              return apiError;
            }
          }
          // Check for "message" field directly (alternative format)
          final messageField = decoded['message'];
          if (messageField is String) {
            return HttpFailure(
              statusCode: response.statusCode,
              message: messageField,
            );
          }
        } else if (decoded is String) {
          // API returned a plain string error
          return HttpFailure(
            statusCode: response.statusCode,
            message: decoded,
          );
        }
      }
    } catch (_) {
      // Ignore parsing errors - will fall through to default HttpFailure
    }

    return HttpFailure(
      statusCode: response.statusCode,
      message: _getMessageForStatusCode(response.statusCode),
    );
  }

  static String _getMessageForStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not found';
      case 500:
        return 'Internal server error';
      case 502:
        return 'Bad gateway';
      case 503:
        return 'Service unavailable';
      default:
        return 'HTTP error $statusCode';
    }
  }
}

/// Failure for structured API errors returned by the backend.
class ApiError extends Failure {
  final String code;

  const ApiError({
    required this.code,
    required String message,
  }) : super(message);

  @override
  List<Object?> get props => [code, message];

  /// Parses an ApiError from a JSON DTO.
  /// Returns null if the DTO is null or invalid.
  static ApiError? fromJsonDto(Map<String, dynamic>? dto) {
    if (dto == null) return null;

    return ApiError(
      code: dto['code'] as String? ?? 'UNKNOWN',
      message: dto['message'] as String? ?? 'An error occurred',
    );
  }
}

/// Failure for validation errors.
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required String message,
    this.fieldErrors,
  }) : super(message);

  @override
  List<Object?> get props => [message, fieldErrors];
}
