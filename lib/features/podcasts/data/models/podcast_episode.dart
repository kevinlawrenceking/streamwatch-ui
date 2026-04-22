import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable model representing a podcast episode (read-only).
///
/// Base fields (id, podcastId, title, sourceUrl, source, publishedAt,
/// createdAt) serve the LSW-004 episode list. The 4 optional status fields
/// (discoveredAt, processingStatus, transcriptStatus, reviewedAt) are added
/// for WO-076 reports drill-downs so ReportedEpisodeCard can render editorial
/// context and so action eligibility can be derived from episode fields
/// rather than inferred from the report slug alone.
@immutable
class PodcastEpisodeModel extends Equatable {
  final String id;
  final String podcastId;
  final String title;
  final String? sourceUrl;
  final String? source;
  final DateTime? publishedAt;
  final DateTime createdAt;

  // Added by WO-076 (LSW-014). Nullable because earlier list endpoints do not
  // return them — back-compat with the LSW-004 episode list is preserved.
  final DateTime? discoveredAt;
  final String? processingStatus;
  final String? transcriptStatus;
  final DateTime? reviewedAt;

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
      discoveredAt: json['discovered_at'] != null
          ? DateTime.parse(json['discovered_at'] as String)
          : null,
      processingStatus: json['processing_status'] as String?,
      transcriptStatus: json['transcript_status'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
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
      ];
}
