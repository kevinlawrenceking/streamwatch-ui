import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Request DTO for `/api/v1/podcast-guest-watchlist/{id}/change-status`.
///
/// Per KB section 18f.5 LOCK H ordering, the handler enforces:
///   * `status` must be `matched` or `expired` (active is never a valid target)
///   * if `status == 'matched'` then `matchedEpisodeId` is required and
///     `expiresAt` is forbidden
///   * if `status == 'expired'` then `matchedEpisodeId` is forbidden
///
/// Validation here mirrors the server contract so we surface friendly toast
/// text before round-tripping (see toast L-8 / L-9 in WO-078 KB section 31.12).
@immutable
class ChangeWatchlistStatusRequest extends Equatable {
  final String status; // 'matched' | 'expired'
  final String? matchedEpisodeId;
  final DateTime? expiresAt;

  const ChangeWatchlistStatusRequest({
    required this.status,
    this.matchedEpisodeId,
    this.expiresAt,
  });

  Map<String, dynamic> toJsonDto() {
    return {
      'status': status,
      if (matchedEpisodeId != null) 'matched_episode_id': matchedEpisodeId,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    };
  }

  ChangeWatchlistStatusRequest copyWith({
    String? status,
    String? matchedEpisodeId,
    DateTime? expiresAt,
  }) {
    return ChangeWatchlistStatusRequest(
      status: status ?? this.status,
      matchedEpisodeId: matchedEpisodeId ?? this.matchedEpisodeId,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  List<Object?> get props => [status, matchedEpisodeId, expiresAt];
}
