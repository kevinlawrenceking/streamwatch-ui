import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Per-item result row inside a 207 Multi-Status response from
/// `POST /api/v1/detections/batch-trigger`.
///
/// Per KB section 18g.9: `status` is the literal HTTP status code for the
/// item (202 / 409 / 404 / 5xx) -- NOT a string enum. This matches the
/// `failure.statusCode` discrimination idiom used elsewhere (see toast
/// table in WO-078 KB section 31.12).
///
///   * 202 -> `runId` populated
///   * 409 -> `errorCode` like `ALREADY_ACTIVE`
///   * 404 -> `errorCode` like `EPISODE_NOT_FOUND`
@immutable
class BatchTriggerItemResult extends Equatable {
  final String episodeId;
  final int status; // HTTP code: 202 / 409 / 404 / 5xx
  final String? runId;
  final String? errorCode;

  const BatchTriggerItemResult({
    required this.episodeId,
    required this.status,
    this.runId,
    this.errorCode,
  });

  factory BatchTriggerItemResult.fromJsonDto(Map<String, dynamic> json) {
    return BatchTriggerItemResult(
      episodeId: json['episode_id'] as String,
      status: json['status'] as int,
      runId: json['run_id'] as String?,
      errorCode: json['error_code'] as String?,
    );
  }

  Map<String, dynamic> toJsonDto() {
    return {
      'episode_id': episodeId,
      'status': status,
      if (runId != null) 'run_id': runId,
      if (errorCode != null) 'error_code': errorCode,
    };
  }

  bool get isSuccess => status == 202;
  bool get isConflict => status == 409;
  bool get isNotFound => status == 404;

  BatchTriggerItemResult copyWith({
    String? episodeId,
    int? status,
    String? runId,
    String? errorCode,
  }) {
    return BatchTriggerItemResult(
      episodeId: episodeId ?? this.episodeId,
      status: status ?? this.status,
      runId: runId ?? this.runId,
      errorCode: errorCode ?? this.errorCode,
    );
  }

  @override
  List<Object?> get props => [episodeId, status, runId, errorCode];
}

/// Envelope wrapper for the 207 Multi-Status response body.
///
/// Shape (per KB section 18g.9):
/// ```json
/// {"results": [{"episode_id": "...", "status": 202, "run_id": "..."}, ...]}
/// ```
@immutable
class BatchTriggerResponse extends Equatable {
  final List<BatchTriggerItemResult> results;

  const BatchTriggerResponse({required this.results});

  factory BatchTriggerResponse.fromJsonDto(Map<String, dynamic> json) {
    final raw = json['results'];
    final items = raw is List
        ? raw
            .map((e) =>
                BatchTriggerItemResult.fromJsonDto(e as Map<String, dynamic>))
            .toList(growable: false)
        : const <BatchTriggerItemResult>[];
    return BatchTriggerResponse(results: items);
  }

  Map<String, dynamic> toJsonDto() {
    return {
      'results': results.map((r) => r.toJsonDto()).toList(),
    };
  }

  @override
  List<Object?> get props => [results];
}
