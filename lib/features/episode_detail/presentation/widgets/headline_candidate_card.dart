import 'package:flutter/material.dart';

import '../../../../themes/app_theme.dart';
import '../../../podcasts/data/models/podcast_headline_candidate.dart';

/// Single-row presentation for a PodcastHeadlineCandidateModel. Approve +
/// Delete inline actions; status badge.
class HeadlineCandidateCard extends StatelessWidget {
  final PodcastHeadlineCandidateModel candidate;
  final bool inFlight;
  final VoidCallback? onApprove;
  final VoidCallback? onDelete;

  const HeadlineCandidateCard({
    super.key,
    required this.candidate,
    this.inFlight = false,
    this.onApprove,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isApproved = candidate.status == 'approved';
    final isPending = candidate.status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    candidate.text ?? '(no text)',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                _statusBadge(context),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (candidate.score != null)
                  Text(
                    'score: ${candidate.score!.toStringAsFixed(2)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: AppColors.textDim, fontSize: 11),
                  ),
                const Spacer(),
                if (isPending)
                  TextButton.icon(
                    key: Key('headline_card.approve.${candidate.id}'),
                    onPressed: inFlight ? null : onApprove,
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Approve'),
                  ),
                IconButton(
                  key: Key('headline_card.delete.${candidate.id}'),
                  tooltip: 'Delete',
                  onPressed: (inFlight || isApproved) ? null : onDelete,
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AppColors.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(BuildContext context) {
    final color = switch (candidate.status) {
      'approved' => AppColors.success,
      'generating' => AppColors.info,
      'rejected' => AppColors.error,
      'failed' => AppColors.error,
      _ => AppColors.textDim,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        candidate.status.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: AppColors.textMax,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
      ),
    );
  }
}
