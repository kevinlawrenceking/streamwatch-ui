import 'package:flutter/material.dart';

import '../../../../themes/app_theme.dart';
import '../../../podcasts/data/models/podcast_episode.dart';
import 'action_eligibility.dart';

/// Row presentation for a PodcastEpisodeModel in an episode-valued
/// drill-down. The action row is conditional per report + episode state
/// (see action_eligibility.dart). In-flight taps show a spinner and disable
/// both buttons on the card.
class ReportedEpisodeCard extends StatelessWidget {
  final PodcastEpisodeModel episode;
  final String reportKey;
  final Color accentColor;
  final bool inFlight;
  final VoidCallback? onMarkReviewed;
  final VoidCallback? onRequestClip;

  const ReportedEpisodeCard({
    super.key,
    required this.episode,
    required this.reportKey,
    required this.accentColor,
    this.inFlight = false,
    this.onMarkReviewed,
    this.onRequestClip,
  });

  @override
  Widget build(BuildContext context) {
    final showMarkReviewed = canMarkReviewed(reportKey, episode);
    final showRequestClip = canRequestClip(reportKey, episode);
    final anyAction = showMarkReviewed || showRequestClip;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statusBar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        episode.title,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _metadataLine(),
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: AppColors.textDim,
                              fontSize: 11,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (inFlight)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
            if (anyAction) const SizedBox(height: 8),
            if (anyAction)
              Row(
                children: [
                  if (showMarkReviewed)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OutlinedButton.icon(
                        onPressed: inFlight ? null : onMarkReviewed,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Mark Reviewed'),
                      ),
                    ),
                  if (showRequestClip)
                    OutlinedButton.icon(
                      onPressed: inFlight ? null : onRequestClip,
                      icon: const Icon(Icons.content_cut, size: 16),
                      label: const Text('Request Clip'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusBar() {
    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  String _metadataLine() {
    final parts = <String>[];
    final ps = episode.processingStatus;
    if (ps != null && ps.isNotEmpty) parts.add('status: $ps');
    final ts = episode.transcriptStatus;
    if (ts != null && ts.isNotEmpty) parts.add('transcript: $ts');
    final reviewed = episode.reviewedAt;
    if (reviewed != null) parts.add('reviewed ${_formatDate(reviewed)}');
    final discovered = episode.discoveredAt;
    if (discovered != null && reviewed == null) {
      parts.add('discovered ${_formatDate(discovered)}');
    }
    if (parts.isEmpty) {
      final pub = episode.publishedAt;
      if (pub != null) parts.add(_formatDate(pub));
    }
    return parts.join('  •  ');
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
