import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable model representing a podcast episode (read-only).
@immutable
class PodcastEpisodeModel extends Equatable {
  final String id;
  final String podcastId;
  final String title;
  final String? sourceUrl;
  final String? source;
  final DateTime? publishedAt;
  final DateTime createdAt;

  const PodcastEpisodeModel({
    required this.id,
    required this.podcastId,
    required this.title,
    this.sourceUrl,
    this.source,
    this.publishedAt,
    required this.createdAt,
  });

  factory PodcastEpisodeModel.fromJsonDto(Map<String, dynamic> json) {
    return PodcastEpisodeModel(
      id: json['id'] as String,
      podcastId: json['podcast_id'] as String,
      title: json['title'] as String,
      sourceUrl: json['source_url'] as String?,
      source: json['source'] as String?,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [id, podcastId, title, sourceUrl, source, publishedAt, createdAt];
}
