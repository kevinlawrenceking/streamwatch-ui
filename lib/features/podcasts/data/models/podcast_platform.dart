import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable model representing a podcast platform link.
@immutable
class PodcastPlatformModel extends Equatable {
  final String id;
  final String podcastId;
  final String platformName;
  final String platformUrl;

  const PodcastPlatformModel({
    required this.id,
    required this.podcastId,
    required this.platformName,
    required this.platformUrl,
  });

  factory PodcastPlatformModel.fromJsonDto(Map<String, dynamic> json) {
    final name = json['platform_name'] as String? ??
        (json.containsKey('youtube_channel_id') ? 'YouTube' : 'Unknown');
    final url =
        json['platform_url'] as String? ?? json['feed_url'] as String? ?? '';
    return PodcastPlatformModel(
      id: json['id'] as String,
      podcastId: json['podcast_id'] as String,
      platformName: name,
      platformUrl: url,
    );
  }

  Map<String, dynamic> toJsonDto() {
    return {
      'platform_name': platformName,
      'platform_url': platformUrl,
    };
  }

  PodcastPlatformModel copyWith({
    String? id,
    String? podcastId,
    String? platformName,
    String? platformUrl,
  }) {
    return PodcastPlatformModel(
      id: id ?? this.id,
      podcastId: podcastId ?? this.podcastId,
      platformName: platformName ?? this.platformName,
      platformUrl: platformUrl ?? this.platformUrl,
    );
  }

  @override
  List<Object?> get props => [id, podcastId, platformName, platformUrl];
}
