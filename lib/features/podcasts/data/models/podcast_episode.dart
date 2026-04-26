import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable model representing a podcast episode (read + edit-metadata).
///
/// Field history:
///   LSW-004 base (7): id, podcastId, title, sourceUrl, source, publishedAt,
///     createdAt
///   WO-076 / LSW-014 D2 (+4): discoveredAt, processingStatus,
///     transcriptStatus, reviewedAt
///   WO-077 / LSW-015 D2 continuation (+6): episodeDescription,
///     platformEpisodeUrl, platformType, guestNames, headlineStatus,
///     notificationStatus
///
/// All WO-076 + WO-077 additions are nullable so back-compat with the
/// LSW-004 list endpoint is preserved (missing keys default null/empty).
@immutable
class PodcastEpisodeModel extends Equatable {
  // --- LSW-004 base (7) -----------------------------------------------------
  final String id;
  final String podcastId;
  final String title;
  final String? sourceUrl;
  final String? source;
  final DateTime? publishedAt;
  final DateTime createdAt;

  // --- WO-076 / LSW-014 (+4) ------------------------------------------------
  final DateTime? discoveredAt;
  final String? processingStatus;
  final String? transcriptStatus;
  final DateTime? reviewedAt;

  // --- WO-077 / LSW-015 (+6) ------------------------------------------------
  final String? episodeDescription;
  final String? platformEpisodeUrl;
  final String? platformType;
  final List<String>? guestNames;
  final String? headlineStatus;
  final String? notificationStatus;

  const PodcastEpisodeModel({
    required this.id,
    required this.podcastId,
    required this.title,
    this.sourceUrl,
    this.source,
    this.publishedAt,
    required this.createdAt,
    this.discoveredAt,
    this.processingStatus,
    this.transcriptStatus,
    this.reviewedAt,
    this.episodeDescription,
    this.platformEpisodeUrl,
    this.platformType,
    this.guestNames,
    this.headlineStatus,
    this.notificationStatus,
  });

  factory PodcastEpisodeModel.fromJsonDto(Map<String, dynamic> json) {
    final guestRaw = json['guest_names'];
    final guestNames = guestRaw is List
        ? guestRaw.map((e) => e.toString()).toList(growable: false)
        : null;

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
      discoveredAt: json['discovered_at'] != null
          ? DateTime.parse(json['discovered_at'] as String)
          : null,
      processingStatus: json['processing_status'] as String?,
      transcriptStatus: json['transcript_status'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      episodeDescription: json['episode_description'] as String?,
      platformEpisodeUrl: json['platform_episode_url'] as String?,
      platformType: json['platform_type'] as String?,
      guestNames: guestNames,
      headlineStatus: json['headline_status'] as String?,
      notificationStatus: json['notification_status'] as String?,
    );
  }

  PodcastEpisodeModel copyWith({
    String? id,
    String? podcastId,
    String? title,
    String? sourceUrl,
    String? source,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? discoveredAt,
    String? processingStatus,
    String? transcriptStatus,
    DateTime? reviewedAt,
    String? episodeDescription,
    String? platformEpisodeUrl,
    String? platformType,
    List<String>? guestNames,
    String? headlineStatus,
    String? notificationStatus,
  }) {
    return PodcastEpisodeModel(
      id: id ?? this.id,
      podcastId: podcastId ?? this.podcastId,
      title: title ?? this.title,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      source: source ?? this.source,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      processingStatus: processingStatus ?? this.processingStatus,
      transcriptStatus: transcriptStatus ?? this.transcriptStatus,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      episodeDescription: episodeDescription ?? this.episodeDescription,
      platformEpisodeUrl: platformEpisodeUrl ?? this.platformEpisodeUrl,
      platformType: platformType ?? this.platformType,
      guestNames: guestNames ?? this.guestNames,
      headlineStatus: headlineStatus ?? this.headlineStatus,
      notificationStatus: notificationStatus ?? this.notificationStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        podcastId,
        title,
        sourceUrl,
        source,
        publishedAt,
        createdAt,
        discoveredAt,
        processingStatus,
        transcriptStatus,
        reviewedAt,
        episodeDescription,
        platformEpisodeUrl,
        platformType,
        guestNames,
        headlineStatus,
        notificationStatus,
      ];
}
