import '../../../podcasts/data/models/podcast_episode.dart';

/// Reports where inline actions are never shown, regardless of episode state.
const Set<String> _reportsWithNoActions = <String>{
  'transcript-pending',
  'pending-clip-request',
};

/// processing_status values strictly before `clip_requested` in the WO-059
/// forward-only state machine (detected -> transcribed -> reviewed ->
/// clip_requested -> completed). Null/unknown treated as earliest stage.
const Set<String> _preClipRequestedStatuses = <String>{
  'detected',
  'transcribed',
  'reviewed',
};

/// Should the "Mark Reviewed" button render for this episode in this report?
///
/// Per WO-076 E6:
///   - transcript-pending, pending-clip-request: never shown
///   - pending-review: shown (by report semantics every row qualifies, but
///     the field-level gate is preserved defensively)
///   - recent, headline-ready: shown iff
///     reviewed_at IS NULL AND transcript_status = 'ready'
bool canMarkReviewed(String reportKey, PodcastEpisodeModel episode) {
  if (_reportsWithNoActions.contains(reportKey)) return false;
  return episode.reviewedAt == null && episode.transcriptStatus == 'ready';
}

/// Should the "Request Clip" button render for this episode in this report?
///
/// Per WO-076 E6:
///   - transcript-pending, pending-clip-request, pending-review: never shown
///   - recent, headline-ready: shown iff processing_status is pre-
///     'clip_requested' (detected / transcribed / reviewed / unknown)
bool canRequestClip(String reportKey, PodcastEpisodeModel episode) {
  if (_reportsWithNoActions.contains(reportKey)) return false;
  if (reportKey == 'pending-review') return false;
  final s = episode.processingStatus;
  return s == null || _preClipRequestedStatuses.contains(s);
}
