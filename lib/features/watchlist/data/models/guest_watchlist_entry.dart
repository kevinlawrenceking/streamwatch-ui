import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable model representing a podcast guest watchlist entry.
///
/// Two-sink terminal state machine (KB section 18f.4):
/// `active` is the only non-terminal state. Both `matched` and `expired`
/// are terminal sinks (no resurrection).
///
/// Allowlist for PATCH: `guestName`, `aliases`, `reason`, `priority` only
/// (KB section 18f.6) -- enforced at the request DTO layer.
@immutable
class PodcastGuestWatchlistEntry extends Equatable {
  final String id;
  final String guestName;
  final List<String> aliases;
  final String? reason;
  final String priority; // 'high' | 'medium' | 'low'
  final String status; // 'active' | 'matched' | 'expired'
  final String? matchedEpisodeId;
  final DateTime? matchedAt;
  final DateTime? expiresAt;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PodcastGuestWatchlistEntry({
    required this.id,
    required this.guestName,
    required this.aliases,
    this.reason,
    required this.priority,
    required this.status,
    this.matchedEpisodeId,
    this.matchedAt,
    this.expiresAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PodcastGuestWatchlistEntry.fromJsonDto(Map<String, dynamic> json) {
    final aliasesRaw = json['aliases'];
    final aliases = aliasesRaw is List
        ? aliasesRaw.map((e) => e.toString()).toList(growable: false)
        : const <String>[];

    return PodcastGuestWatchlistEntry(
      id: json['id'] as String,
      guestName: json['guest_name'] as String,
      aliases: aliases,
      reason: json['reason'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'active',
      matchedEpisodeId: json['matched_episode_id'] as String?,
      matchedAt: json['matched_at'] != null
          ? DateTime.parse(json['matched_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJsonDto() {
    return {
      'id': id,
      'guest_name': guestName,
      'aliases': aliases,
      if (reason != null) 'reason': reason,
      'priority': priority,
      'status': status,
      if (matchedEpisodeId != null) 'matched_episode_id': matchedEpisodeId,
      if (matchedAt != null) 'matched_at': matchedAt!.toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == 'active';
  bool get isMatched => status == 'matched';
  bool get isExpired => status == 'expired';
  bool get isTerminal => isMatched || isExpired;

  PodcastGuestWatchlistEntry copyWith({
    String? id,
    String? guestName,
    List<String>? aliases,
    String? reason,
    String? priority,
    String? status,
    String? matchedEpisodeId,
    DateTime? matchedAt,
    DateTime? expiresAt,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PodcastGuestWatchlistEntry(
      id: id ?? this.id,
      guestName: guestName ?? this.guestName,
      aliases: aliases ?? this.aliases,
      reason: reason ?? this.reason,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      matchedEpisodeId: matchedEpisodeId ?? this.matchedEpisodeId,
      matchedAt: matchedAt ?? this.matchedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        guestName,
        aliases,
        reason,
        priority,
        status,
        matchedEpisodeId,
        matchedAt,
        expiresAt,
        createdBy,
        createdAt,
        updatedAt,
      ];
}
