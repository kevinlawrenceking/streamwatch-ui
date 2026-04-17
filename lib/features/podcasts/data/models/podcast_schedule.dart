import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable model representing a podcast schedule slot.
@immutable
class PodcastScheduleModel extends Equatable {
  final String id;
  final String podcastId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String timezone;

  const PodcastScheduleModel({
    required this.id,
    required this.podcastId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.timezone,
  });

  factory PodcastScheduleModel.fromJsonDto(Map<String, dynamic> json) {
    return PodcastScheduleModel(
      id: json['id'] as String,
      podcastId: json['podcast_id'] as String,
      dayOfWeek: json['day_of_week'] as String,
      startTime: json['start_time'] as String? ??
          json['start_time_pt'] as String? ??
          '',
      endTime: json['end_time'] as String? ?? '',
      timezone: json['timezone'] as String? ?? 'America/Los_Angeles',
    );
  }

  Map<String, dynamic> toJsonDto() {
    return {
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'timezone': timezone,
    };
  }

  PodcastScheduleModel copyWith({
    String? id,
    String? podcastId,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    String? timezone,
  }) {
    return PodcastScheduleModel(
      id: id ?? this.id,
      podcastId: podcastId ?? this.podcastId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      timezone: timezone ?? this.timezone,
    );
  }

  @override
  List<Object?> get props =>
      [id, podcastId, dayOfWeek, startTime, endTime, timezone];
}
