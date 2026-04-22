import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable model for a single podcast schedule slot row.
///
/// Mirrors the Go `models.PodcastScheduleSlot` struct returned by the
/// slot-valued WO-065 reports (expected-today, late). 17 fields — matches
/// `reportSlotCols` in `streamwatch-api-legacy/internal/data/sources/podcast.go`.
/// `schedule_confidence` is intentionally `String?` (not numeric) because the
/// Go struct uses `*string`.
@immutable
class PodcastScheduleSlot extends Equatable {
  final String id;
  final String podcastId;
  final String? dayOfWeek;
  final String? startTimePt;
  final String? timeTextRaw;
  final String source;
  final String? timePrecision;
  final String? scheduleConfidence;
  final String? releaseWindowStart;
  final String? releaseWindowEnd;
  final int? checkBeforeMinutes;
  final int? latenessGraceMinutes;
  final int? priorityRank;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PodcastScheduleSlot({
    required this.id,
    required this.podcastId,
    this.dayOfWeek,
    this.startTimePt,
    this.timeTextRaw,
    required this.source,
    this.timePrecision,
    this.scheduleConfidence,
    this.releaseWindowStart,
    this.releaseWindowEnd,
    this.checkBeforeMinutes,
    this.latenessGraceMinutes,
    this.priorityRank,
    required this.isActive,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PodcastScheduleSlot.fromJsonDto(Map<String, dynamic> json) {
    return PodcastScheduleSlot(
      id: json['id'] as String,
      podcastId: json['podcast_id'] as String,
      dayOfWeek: json['day_of_week'] as String?,
      startTimePt: json['start_time_pt'] as String?,
      timeTextRaw: json['time_text_raw'] as String?,
      source: (json['source'] as String?) ?? '',
      timePrecision: json['time_precision'] as String?,
      scheduleConfidence: json['schedule_confidence'] as String?,
      releaseWindowStart: json['release_window_start'] as String?,
      releaseWindowEnd: json['release_window_end'] as String?,
      checkBeforeMinutes: (json['check_before_minutes'] as num?)?.toInt(),
      latenessGraceMinutes: (json['lateness_grace_minutes'] as num?)?.toInt(),
      priorityRank: (json['priority_rank'] as num?)?.toInt(),
      isActive: (json['is_active'] as bool?) ?? false,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJsonDto() {
    return {
      'id': id,
      'podcast_id': podcastId,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (startTimePt != null) 'start_time_pt': startTimePt,
      if (timeTextRaw != null) 'time_text_raw': timeTextRaw,
      'source': source,
      if (timePrecision != null) 'time_precision': timePrecision,
      if (scheduleConfidence != null) 'schedule_confidence': scheduleConfidence,
      if (releaseWindowStart != null) 'release_window_start': releaseWindowStart,
      if (releaseWindowEnd != null) 'release_window_end': releaseWindowEnd,
      if (checkBeforeMinutes != null) 'check_before_minutes': checkBeforeMinutes,
      if (latenessGraceMinutes != null) 'lateness_grace_minutes': latenessGraceMinutes,
      if (priorityRank != null) 'priority_rank': priorityRank,
      'is_active': isActive,
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        podcastId,
        dayOfWeek,
        startTimePt,
        timeTextRaw,
        source,
        timePrecision,
        scheduleConfidence,
        releaseWindowStart,
        releaseWindowEnd,
        checkBeforeMinutes,
        latenessGraceMinutes,
        priorityRank,
        isActive,
        notes,
        createdAt,
        updatedAt,
      ];
}
