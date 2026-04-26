import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable model representing a podcast notification
/// (LSW-007-D / WO-062). Channel constrained to {ses, slack} server-side.
/// Status forward-only: pending -> sent. Side-terminal: failed.
///
/// Multiple notifications per episode are permitted (no UNIQUE on episode_id)
/// — one to editorial, one to newsroom, etc.
@immutable
class PodcastNotificationModel extends Equatable {
  final String id;
  final String episodeId;
  final String channel;
  final String? recipient;
  final String subject;
  final String body;
  final String status;
  final DateTime? sentAt;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PodcastNotificationModel({
    required this.id,
    required this.episodeId,
    required this.channel,
    this.recipient,
    required this.subject,
    required this.body,
    required this.status,
    this.sentAt,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PodcastNotificationModel.fromJsonDto(Map<String, dynamic> json) {
    return PodcastNotificationModel(
      id: json['id'] as String,
      episodeId: json['episode_id'] as String,
      channel: json['channel'] as String,
      recipient: json['recipient'] as String?,
      subject: json['subject'] as String? ?? '',
      body: json['body'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJsonDto() {
    return <String, dynamic>{
      'id': id,
      'episode_id': episodeId,
      'channel': channel,
      if (recipient != null) 'recipient': recipient,
      'subject': subject,
      'body': body,
      'status': status,
      if (sentAt != null) 'sent_at': sentAt!.toIso8601String(),
      if (errorMessage != null) 'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PodcastNotificationModel copyWith({
    String? id,
    String? episodeId,
    String? channel,
    String? recipient,
    String? subject,
    String? body,
    String? status,
    DateTime? sentAt,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PodcastNotificationModel(
      id: id ?? this.id,
      episodeId: episodeId ?? this.episodeId,
      channel: channel ?? this.channel,
      recipient: recipient ?? this.recipient,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        episodeId,
        channel,
        recipient,
        subject,
        body,
        status,
        sentAt,
        errorMessage,
        createdAt,
        updatedAt,
      ];
}
