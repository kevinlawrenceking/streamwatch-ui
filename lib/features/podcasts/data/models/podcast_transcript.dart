import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable model representing a podcast transcript variant
/// (LSW-007-B / WO-060). Multiple transcripts may exist per episode;
/// at most one is_primary=true per episode (DB partial unique index).
@immutable
class PodcastTranscriptModel extends Equatable {
  final String id;
  final String episodeId;
  final String variant;
  final String sourceType;
  final String? text;
  final Map<String, dynamic>? transcriptJson;
  final bool isPrimary;
  final String? languageCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PodcastTranscriptModel({
    required this.id,
    required this.episodeId,
    required this.variant,
    required this.sourceType,
    this.text,
    this.transcriptJson,
    this.isPrimary = false,
    this.languageCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PodcastTranscriptModel.fromJsonDto(Map<String, dynamic> json) {
    return PodcastTranscriptModel(
      id: json['id'] as String,
      episodeId: json['episode_id'] as String,
      variant: json['variant'] as String,
      sourceType: json['source_type'] as String,
      text: json['text'] as String?,
      transcriptJson: json['transcript_json'] as Map<String, dynamic>?,
      isPrimary: json['is_primary'] as bool? ?? false,
      languageCode: json['language_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJsonDto() {
    return <String, dynamic>{
      'id': id,
      'episode_id': episodeId,
      'variant': variant,
      'source_type': sourceType,
      if (text != null) 'text': text,
      if (transcriptJson != null) 'transcript_json': transcriptJson,
      'is_primary': isPrimary,
      if (languageCode != null) 'language_code': languageCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PodcastTranscriptModel copyWith({
    String? id,
    String? episodeId,
    String? variant,
    String? sourceType,
    String? text,
    Map<String, dynamic>? transcriptJson,
    bool? isPrimary,
    String? languageCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PodcastTranscriptModel(
      id: id ?? this.id,
      episodeId: episodeId ?? this.episodeId,
      variant: variant ?? this.variant,
      sourceType: sourceType ?? this.sourceType,
      text: text ?? this.text,
      transcriptJson: transcriptJson ?? this.transcriptJson,
      isPrimary: isPrimary ?? this.isPrimary,
      languageCode: languageCode ?? this.languageCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        episodeId,
        variant,
        sourceType,
        text,
        transcriptJson,
        isPrimary,
        languageCode,
        createdAt,
        updatedAt,
      ];
}
