import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable model for a podcast pipeline job row from
/// `GET /api/v1/podcast-jobs`.
///
/// `retryCount`, `lastRetryAt`, `lastRetryBy` are populated by the
/// retry handler per KB section 18g.5 (amendment 3): the transactional
/// reset stamps these even if the SQS enqueue subsequently fails so the
/// failed attempt remains visible in job history.
///
/// On 202 Accepted from `POST /api/v1/podcast-jobs/{id}/retry`, the BLoC
/// optimistically flips `status` to `'queued'` (toast L-1).
@immutable
class PodcastJob extends Equatable {
  final String jobId;
  final String? podcastId;
  final String? episodeId;
  final String status;
  final String? sourceUrl;
  final String? title;
  final String? errorCode;
  final String? errorMessage;
  final int retryCount;
  final DateTime? lastRetryAt;
  final String? lastRetryBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PodcastJob({
    required this.jobId,
    this.podcastId,
    this.episodeId,
    required this.status,
    this.sourceUrl,
    this.title,
    this.errorCode,
    this.errorMessage,
    this.retryCount = 0,
    this.lastRetryAt,
    this.lastRetryBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory PodcastJob.fromJsonDto(Map<String, dynamic> json) {
    return PodcastJob(
      jobId: (json['job_id'] ?? json['id']) as String,
      podcastId: json['podcast_id'] as String?,
      episodeId: json['episode_id'] as String?,
      status: json['status'] as String,
      sourceUrl: json['source_url'] as String?,
      title: json['title'] as String?,
      errorCode: json['error_code'] as String?,
      errorMessage: json['error_message'] as String?,
      retryCount: json['retry_count'] as int? ?? 0,
      lastRetryAt: json['last_retry_at'] != null
          ? DateTime.parse(json['last_retry_at'] as String)
          : null,
      lastRetryBy: json['last_retry_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJsonDto() {
    return {
      'job_id': jobId,
      if (podcastId != null) 'podcast_id': podcastId,
      if (episodeId != null) 'episode_id': episodeId,
      'status': status,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (title != null) 'title': title,
      if (errorCode != null) 'error_code': errorCode,
      if (errorMessage != null) 'error_message': errorMessage,
      'retry_count': retryCount,
      if (lastRetryAt != null) 'last_retry_at': lastRetryAt!.toIso8601String(),
      if (lastRetryBy != null) 'last_retry_by': lastRetryBy,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  PodcastJob copyWith({
    String? jobId,
    String? podcastId,
    String? episodeId,
    String? status,
    String? sourceUrl,
    String? title,
    String? errorCode,
    String? errorMessage,
    int? retryCount,
    DateTime? lastRetryAt,
    String? lastRetryBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PodcastJob(
      jobId: jobId ?? this.jobId,
      podcastId: podcastId ?? this.podcastId,
      episodeId: episodeId ?? this.episodeId,
      status: status ?? this.status,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      title: title ?? this.title,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
      lastRetryBy: lastRetryBy ?? this.lastRetryBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        jobId,
        podcastId,
        episodeId,
        status,
        sourceUrl,
        title,
        errorCode,
        errorMessage,
        retryCount,
        lastRetryAt,
        lastRetryBy,
        createdAt,
        updatedAt,
      ];
}
