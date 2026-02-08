import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable model representing a video processing job.
///
/// Uses Equatable for value equality, which is required for proper
/// BLoC state comparison and change detection.
@immutable
class JobModel extends Equatable {
  final String jobId;
  final String source;
  final String? sourceUrl;
  final String? sourceProvider;
  final String? filePath;
  final String? filename;
  final String? storagePath;
  final String? title;
  final String? description;
  final String status;
  final int progressPct;
  final int completedChunks;
  final String? errorMessage;
  final String? finalSummary;
  final String? summaryText;
  final String? fullTranscript;
  final String? transcriptFinal;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  // Soft delete fields
  final DateTime? deletedAt;
  final String? deletedBy;

  // Flag fields
  final bool isFlagged;
  final DateTime? flaggedAt;
  final String? flaggedBy;
  final String? flagNote;

  // Pause/resume fields
  final bool pauseRequested;
  final DateTime? pauseRequestedAt;
  final DateTime? pausedAt;
  final DateTime? resumedAt;

  // Worker heartbeat fields
  final DateTime? workerHeartbeatAt;
  final String? currentStage;

  // Type classification fields (editorial content format)
  final int? typeId;
  final String? typeCode;
  final double? typeConfidence;
  final DateTime? typeClassifiedAt;

  const JobModel({
    required this.jobId,
    required this.source,
    this.sourceUrl,
    this.sourceProvider,
    this.filePath,
    this.filename,
    this.storagePath,
    this.title,
    this.description,
    required this.status,
    required this.progressPct,
    required this.completedChunks,
    this.errorMessage,
    this.finalSummary,
    this.summaryText,
    this.fullTranscript,
    this.transcriptFinal,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    // Soft delete
    this.deletedAt,
    this.deletedBy,
    // Flag
    this.isFlagged = false,
    this.flaggedAt,
    this.flaggedBy,
    this.flagNote,
    // Pause/resume
    this.pauseRequested = false,
    this.pauseRequestedAt,
    this.pausedAt,
    this.resumedAt,
    // Worker heartbeat
    this.workerHeartbeatAt,
    this.currentStage,
    // Type classification
    this.typeId,
    this.typeCode,
    this.typeConfidence,
    this.typeClassifiedAt,
  });

  /// Creates a JobModel from a JSON DTO.
  static JobModel fromJsonDto(Map<String, dynamic>? dto) {
    return JobModel(
      jobId: dto?['job_id'] ?? '',
      source: dto?['source'] ?? 'url',
      sourceUrl: dto?['source_url'],
      sourceProvider: dto?['source_provider'],
      filePath: dto?['file_path'],
      filename: dto?['filename'],
      storagePath: dto?['storage_path'],
      title: dto?['title'],
      description: dto?['description'],
      status: dto?['status'] ?? 'unknown',
      progressPct: dto?['progress_pct'] ?? 0,
      completedChunks: dto?['completed_chunks'] ?? 0,
      errorMessage: dto?['error_message'],
      finalSummary: dto?['final_summary'],
      summaryText: dto?['summary_text'],
      fullTranscript: dto?['full_transcript'],
      transcriptFinal: dto?['transcript_final'],
      createdAt: _parseDateTime(dto?['created_at']) ?? DateTime.now(),
      startedAt: _parseDateTime(dto?['started_at']),
      completedAt: _parseDateTime(dto?['completed_at']),
      // Soft delete
      deletedAt: _parseDateTime(dto?['deleted_at']),
      deletedBy: dto?['deleted_by'],
      // Flag
      isFlagged: dto?['is_flagged'] ?? false,
      flaggedAt: _parseDateTime(dto?['flagged_at']),
      flaggedBy: dto?['flagged_by'],
      flagNote: dto?['flag_note'],
      // Pause/resume
      pauseRequested: dto?['pause_requested'] ?? false,
      pauseRequestedAt: _parseDateTime(dto?['pause_requested_at']),
      pausedAt: _parseDateTime(dto?['paused_at']),
      resumedAt: _parseDateTime(dto?['resumed_at']),
      // Worker heartbeat
      workerHeartbeatAt: _parseDateTime(dto?['worker_heartbeat_at']),
      currentStage: dto?['current_stage'],
      // Type classification
      typeId: dto?['type_id'],
      typeCode: dto?['type_code'],
      typeConfidence: (dto?['type_confidence'] as num?)?.toDouble(),
      typeClassifiedAt: _parseDateTime(dto?['type_classified_at']),
    );
  }

  static DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// Converts the model to a JSON DTO.
  Map<String, dynamic> toJsonDto() {
    return {
      'job_id': jobId,
      'source': source,
      'source_url': sourceUrl,
      'source_provider': sourceProvider,
      'file_path': filePath,
      'filename': filename,
      'storage_path': storagePath,
      'title': title,
      'description': description,
      'status': status,
      'progress_pct': progressPct,
      'completed_chunks': completedChunks,
      'error_message': errorMessage,
      'final_summary': finalSummary,
      'summary_text': summaryText,
      'full_transcript': fullTranscript,
      'transcript_final': transcriptFinal,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      // Soft delete
      'deleted_at': deletedAt?.toIso8601String(),
      'deleted_by': deletedBy,
      // Flag
      'is_flagged': isFlagged,
      'flagged_at': flaggedAt?.toIso8601String(),
      'flagged_by': flaggedBy,
      'flag_note': flagNote,
      // Pause/resume
      'pause_requested': pauseRequested,
      'pause_requested_at': pauseRequestedAt?.toIso8601String(),
      'paused_at': pausedAt?.toIso8601String(),
      'resumed_at': resumedAt?.toIso8601String(),
      // Worker heartbeat
      'worker_heartbeat_at': workerHeartbeatAt?.toIso8601String(),
      'current_stage': currentStage,
      // Type classification
      'type_id': typeId,
      'type_code': typeCode,
      'type_confidence': typeConfidence,
      'type_classified_at': typeClassifiedAt?.toIso8601String(),
    };
  }

  /// Creates a copy of this model with the given fields replaced.
  JobModel copyWith({
    String? jobId,
    String? source,
    String? sourceUrl,
    String? sourceProvider,
    String? filePath,
    String? filename,
    String? storagePath,
    String? title,
    String? description,
    String? status,
    int? progressPct,
    int? completedChunks,
    String? errorMessage,
    String? finalSummary,
    String? summaryText,
    String? fullTranscript,
    String? transcriptFinal,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    // Soft delete
    DateTime? deletedAt,
    String? deletedBy,
    // Flag
    bool? isFlagged,
    DateTime? flaggedAt,
    String? flaggedBy,
    String? flagNote,
    // Pause/resume
    bool? pauseRequested,
    DateTime? pauseRequestedAt,
    DateTime? pausedAt,
    DateTime? resumedAt,
    // Worker heartbeat
    DateTime? workerHeartbeatAt,
    String? currentStage,
    // Type classification
    int? typeId,
    String? typeCode,
    double? typeConfidence,
    DateTime? typeClassifiedAt,
  }) {
    return JobModel(
      jobId: jobId ?? this.jobId,
      source: source ?? this.source,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceProvider: sourceProvider ?? this.sourceProvider,
      filePath: filePath ?? this.filePath,
      filename: filename ?? this.filename,
      storagePath: storagePath ?? this.storagePath,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      progressPct: progressPct ?? this.progressPct,
      completedChunks: completedChunks ?? this.completedChunks,
      errorMessage: errorMessage ?? this.errorMessage,
      finalSummary: finalSummary ?? this.finalSummary,
      summaryText: summaryText ?? this.summaryText,
      fullTranscript: fullTranscript ?? this.fullTranscript,
      transcriptFinal: transcriptFinal ?? this.transcriptFinal,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      // Soft delete
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      // Flag
      isFlagged: isFlagged ?? this.isFlagged,
      flaggedAt: flaggedAt ?? this.flaggedAt,
      flaggedBy: flaggedBy ?? this.flaggedBy,
      flagNote: flagNote ?? this.flagNote,
      // Pause/resume
      pauseRequested: pauseRequested ?? this.pauseRequested,
      pauseRequestedAt: pauseRequestedAt ?? this.pauseRequestedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      resumedAt: resumedAt ?? this.resumedAt,
      // Worker heartbeat
      workerHeartbeatAt: workerHeartbeatAt ?? this.workerHeartbeatAt,
      currentStage: currentStage ?? this.currentStage,
      // Type classification
      typeId: typeId ?? this.typeId,
      typeCode: typeCode ?? this.typeCode,
      typeConfidence: typeConfidence ?? this.typeConfidence,
      typeClassifiedAt: typeClassifiedAt ?? this.typeClassifiedAt,
    );
  }

  // Status convenience getters
  bool get isQueued => status == 'queued';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';
  bool get isPaused => status == 'paused';
  bool get isDeleted => deletedAt != null;

  /// Returns true if the worker is actively processing (heartbeat within threshold)
  bool get isActive {
    if (!isProcessing) return false;
    if (workerHeartbeatAt == null) return false;
    final threshold = DateTime.now().subtract(const Duration(minutes: 2));
    return workerHeartbeatAt!.isAfter(threshold);
  }

  /// Returns true if the worker appears stale (processing but no recent heartbeat)
  bool get isStale {
    if (!isProcessing) return false;
    if (workerHeartbeatAt == null) return true;
    final threshold = DateTime.now().subtract(const Duration(minutes: 2));
    return workerHeartbeatAt!.isBefore(threshold);
  }

  /// Returns true if pausing but not yet paused
  bool get isPausing => pauseRequested && !isPaused;

  /// Returns true if the job can be paused
  bool get canPause => isQueued || isProcessing;

  /// Returns true if the job can be resumed
  bool get canResume => isPaused || pauseRequested;

  /// Returns true if the job can be deleted
  bool get canDelete => !isFlagged && !isProcessing;

  /// Returns true if the job can be cancelled (queued or processing, not already terminal)
  bool get canCancel => isQueued || isProcessing;

  /// Extracts the participants list from finalSummary JSON.
  /// Prefers "participants" (speakers/on-camera subjects only).
  /// Falls back to "people" for jobs processed before the prompt update.
  List<String> get people {
    if (finalSummary == null || finalSummary!.isEmpty) return const [];
    try {
      final parsed = jsonDecode(finalSummary!);
      if (parsed is Map<String, dynamic>) {
        // Prefer participants (new contract: only speakers/on-camera)
        final participants = parsed['participants'];
        if (participants is List && participants.isNotEmpty) {
          return participants.whereType<String>().toList();
        }
        // Fallback: use legacy "people" field (may include mentioned names)
        final list = parsed['people'];
        if (list is List) {
          return list.whereType<String>().toList();
        }
      }
    } catch (_) {
      // finalSummary is not valid JSON or has no people/participants key
    }
    return const [];
  }

  @override
  List<Object?> get props => [
        jobId,
        source,
        sourceUrl,
        sourceProvider,
        filePath,
        filename,
        storagePath,
        title,
        description,
        status,
        progressPct,
        completedChunks,
        errorMessage,
        finalSummary,
        summaryText,
        fullTranscript,
        transcriptFinal,
        createdAt,
        startedAt,
        completedAt,
        // Soft delete
        deletedAt,
        deletedBy,
        // Flag
        isFlagged,
        flaggedAt,
        flaggedBy,
        flagNote,
        // Pause/resume
        pauseRequested,
        pauseRequestedAt,
        pausedAt,
        resumedAt,
        // Worker heartbeat
        workerHeartbeatAt,
        currentStage,
        // Type classification
        typeId,
        typeCode,
        typeConfidence,
        typeClassifiedAt,
      ];
}
