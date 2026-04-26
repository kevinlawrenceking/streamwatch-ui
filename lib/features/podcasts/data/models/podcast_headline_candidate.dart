import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable model representing a podcast headline candidate
/// (LSW-007-C / WO-061). Multiple candidates per episode; partial unique
/// index enforces at-most-one-approved-per-episode at the database level.
///
/// Status forward-only: pending -> generating -> approved.
/// Side-terminal: failed, rejected (allowed from any state, not in order).
@immutable
class PodcastHeadlineCandidateModel extends Equatable {
  final String id;
  final String episodeId;
  final String? text;
  final double? score;
  final String status;
  final String? approvedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PodcastHeadlineCandidateModel({
    required this.id,
    required this.episodeId,
    this.text,
    this.score,
    required this.status,
    this.approvedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PodcastHeadlineCandidateModel.fromJsonDto(Map<String, dynamic> json) {
    return PodcastHeadlineCandidateModel(
      id: json['id'] as String,
      episodeId: json['episode_id'] as String,
      text: json['text'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'pending',
      approvedBy: json['approved_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJsonDto() {
    return <String, dynamic>{
      'id': id,
      'episode_id': episodeId,
      if (text != null) 'text': text,
      if (score != null) 'score': score,
      'status': status,
      if (approvedBy != null) 'approved_by': approvedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PodcastHeadlineCandidateModel copyWith({
    String? id,
    String? episodeId,
    String? text,
    double? score,
    String? status,
    String? approvedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PodcastHeadlineCandidateModel(
      id: id ?? this.id,
      episodeId: episodeId ?? this.episodeId,
      text: text ?? this.text,
      score: score ?? this.score,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        episodeId,
        text,
        score,
        status,
        approvedBy,
        createdAt,
        updatedAt,
      ];
}
