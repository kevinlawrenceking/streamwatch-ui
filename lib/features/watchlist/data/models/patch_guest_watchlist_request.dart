import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// PATCH request DTO for `/api/v1/podcast-guest-watchlist/{id}`.
///
/// Strict allowlist per KB section 18f.6: only the four fields below may
/// be sent. `status`, `matched_episode_id`, `matched_at`, `expires_at`
/// are NOT permitted via PATCH -- those flow through `/change-status`.
///
/// Only non-null fields are emitted by [toJsonDto]. The class shape itself
/// backstops the allowlist so a future refactor cannot accidentally serialize
/// a forbidden field.
@immutable
class PatchGuestWatchlistEntryRequest extends Equatable {
  final String? guestName;
  final List<String>? aliases;
  final String? reason;
  final String? priority;

  const PatchGuestWatchlistEntryRequest({
    this.guestName,
    this.aliases,
    this.reason,
    this.priority,
  });

  /// Returns true if at least one allowlisted field is set.
  /// The handler returns 400 when a PATCH body is empty.
  bool get hasAnyField =>
      guestName != null ||
      aliases != null ||
      reason != null ||
      priority != null;

  Map<String, dynamic> toJsonDto() {
    return {
      if (guestName != null) 'guest_name': guestName,
      if (aliases != null) 'aliases': aliases,
      if (reason != null) 'reason': reason,
      if (priority != null) 'priority': priority,
    };
  }

  PatchGuestWatchlistEntryRequest copyWith({
    String? guestName,
    List<String>? aliases,
    String? reason,
    String? priority,
  }) {
    return PatchGuestWatchlistEntryRequest(
      guestName: guestName ?? this.guestName,
      aliases: aliases ?? this.aliases,
      reason: reason ?? this.reason,
      priority: priority ?? this.priority,
    );
  }

  @override
  List<Object?> get props => [guestName, aliases, reason, priority];
}
