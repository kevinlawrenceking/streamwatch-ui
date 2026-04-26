import '../../../podcasts/data/models/podcast_episode.dart';

/// processing_status values strictly before `clip_requested` in the WO-059
/// forward-only state machine (detected -> transcribed -> reviewed ->
/// clip_requested -> completed). Null/unknown treated as earliest stage.
const Set<String> _preClipRequestedStatuses = <String>{
  'detected',
  'transcribed',
  'reviewed',
};

/// Should the "Mark Reviewed" button render in the EpisodeDetailView action
/// bar for this episode?
///
/// Per WO-077 Plan Lock #1 -- equivalent to the §28 `recent` row, evaluated
/// outside any drill-down report context (no reportKey arg).
bool canMarkReviewed(PodcastEpisodeModel episode) {
  return episode.reviewedAt == null && episode.transcriptStatus == 'ready';
}

/// Should the "Request Clip" button render in the EpisodeDetailView action
/// bar for this episode?
///
/// Per WO-077 Plan Lock #1 -- equivalent to the §28 `recent` row.
bool canRequestClip(PodcastEpisodeModel episode) {
  final s = episode.processingStatus;
  return s == null || _preClipRequestedStatuses.contains(s);
}

/// Should the "Edit Metadata" button render? Always true. Not in the §28
/// matrix; gating decisions stay server-side (PATCH validates field
/// allowlist).
bool canEditMetadata(PodcastEpisodeModel episode) => true;
