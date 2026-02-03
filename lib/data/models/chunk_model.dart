import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable model representing a video chunk/segment.
///
/// Uses Equatable for value equality, which is required for proper
/// BLoC state comparison and change detection.
@immutable
class ChunkModel extends Equatable {
  final String chunkId;
  final String jobId;
  final int orderNo;
  final int startMs;
  final int endMs;
  final String? transcript;
  final String? summary;
  final DateTime createdAt;

  const ChunkModel({
    required this.chunkId,
    required this.jobId,
    required this.orderNo,
    required this.startMs,
    required this.endMs,
    this.transcript,
    this.summary,
    required this.createdAt,
  });

  /// Creates a ChunkModel from a JSON DTO.
  static ChunkModel fromJsonDto(Map<String, dynamic>? dto) {
    return ChunkModel(
      chunkId: dto?['chunk_id'] ?? '',
      jobId: dto?['job_id'] ?? '',
      orderNo: dto?['index'] ?? 0, // Go API returns 'index', not 'order_no'
      startMs: dto?['start_ms'] ?? 0,
      endMs: dto?['end_ms'] ?? 0,
      transcript: dto?['transcript'],
      summary: dto?['summary'],
      createdAt: _parseDateTime(dto?['created_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// Converts the model to a JSON DTO.
  Map<String, dynamic> toJsonDto() {
    return {
      'chunk_id': chunkId,
      'job_id': jobId,
      'index': orderNo,
      'start_ms': startMs,
      'end_ms': endMs,
      'transcript': transcript,
      'summary': summary,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of this model with the given fields replaced.
  ChunkModel copyWith({
    String? chunkId,
    String? jobId,
    int? orderNo,
    int? startMs,
    int? endMs,
    String? transcript,
    String? summary,
    DateTime? createdAt,
  }) {
    return ChunkModel(
      chunkId: chunkId ?? this.chunkId,
      jobId: jobId ?? this.jobId,
      orderNo: orderNo ?? this.orderNo,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      transcript: transcript ?? this.transcript,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Time utilities
  Duration get startTime => Duration(milliseconds: startMs);
  Duration get endTime => Duration(milliseconds: endMs);
  Duration get duration => Duration(milliseconds: endMs - startMs);

  String get formattedTimeRange {
    return '${_formatDuration(startTime)} - ${_formatDuration(endTime)}';
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        chunkId,
        jobId,
        orderNo,
        startMs,
        endMs,
        transcript,
        summary,
        createdAt,
      ];
}
