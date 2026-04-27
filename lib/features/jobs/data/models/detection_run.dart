import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable model for a detection pipeline run from
/// `GET /api/v1/detection-runs`.
///
/// Per KB section 18g.3 schema. Status enum: `queued` | `running` |
/// `succeeded` | `failed`. Single-active invariant for an episode is
/// enforced server-side by `pg_advisory_xact_lock` in
/// `CreateDetectionRun` (KB section 18g.4); concurrent triggers on the
/// same episode serialize and the loser receives 409 ALREADY_ACTIVE
/// (toast L-3 in WO-078 KB section 31.12).
@immutable
class DetectionRun extends Equatable {
  final String id;
  final String episodeId;
  final String? jobId;
  final String status;
  final String? triggeredBy;
  final String? triggerReason;
  final String? errorCode;
  final String? errorMessage;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DetectionRun({
    required this.id,
    required this.episodeId,
    this.jobId,
    required this.status,
    this.triggeredBy,
    this.triggerReason,
    this.errorCode,
    this.errorMessage,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DetectionRun.fromJsonDto(Map<String, dynamic> json) {
    return DetectionRun(
      id: json['id'] as String,
      episodeId: json['episode_id'] as String,
      jobId: json['job_id'] as String?,
      status: json['status'] as String,
      triggeredBy: json['triggered_by'] as String?,
      triggerReason: json['trigger_reason'] as String?,
      errorCode: json['error_code'] as String?,
      errorMessage: json['error_message'] as String?,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJsonDto() {
    return {
      'id': id,
      'episode_id': episodeId,
      if (jobId != null) 'job_id': jobId,
      'status': status,
      if (triggeredBy != null) 'triggered_by': triggeredBy,
      if (triggerReason != null) 'trigger_reason': triggerReason,
      if (errorCode != null) 'error_code': errorCode,
      if (errorMessage != null) 'error_message': errorMessage,
      if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == 'queued' || status == 'running';
  bool get isSucceeded => status == 'succeeded';
  bool get isFailed => status == 'failed';

  DetectionRun copyWith({
    String? id,
    String? episodeId,
    String? jobId,
    String? status,
    String? triggeredBy,
    String? triggerReason,
    String? errorCode,
    String? errorMessage,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DetectionRun(
      id: id ?? this.id,
      episodeId: episodeId ?? this.episodeId,
      jobId: jobId ?? this.jobId,
      status: status ?? this.status,
      triggeredBy: triggeredBy ?? this.triggeredBy,
      triggerReason: triggerReason ?? this.triggerReason,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        episodeId,
        jobId,
        status,
        triggeredBy,
        triggerReason,
        errorCode,
        errorMessage,
        startedAt,
        completedAt,
        createdAt,
        updatedAt,
      ];
}
