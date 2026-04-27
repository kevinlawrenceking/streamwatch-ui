import 'package:flutter/material.dart';

import '../../../../themes/app_theme.dart';
import '../../data/models/podcast_job.dart';

/// One row card for a podcast pipeline job. Retry button is enabled only
/// for failed jobs; everything else shows a status badge + retry-history
/// metadata.
class JobRow extends StatelessWidget {
  final PodcastJob job;
  final bool isRetrying;
  final VoidCallback? onRetry;

  const JobRow({
    super.key,
    required this.job,
    this.isRetrying = false,
    this.onRetry,
  });

  Color _statusColor() {
    switch (job.status) {
      case 'completed':
      case 'succeeded':
        return AppColors.success;
      case 'queued':
      case 'running':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textGhost;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final canRetry = job.status == 'failed' && !isRetrying;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.title ?? job.jobId,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall!
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                _StatusBadge(label: job.status, color: statusColor),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'job ${job.jobId}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (job.podcastId != null)
              Text(
                'podcast ${job.podcastId}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (job.errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                '[${job.errorCode ?? "ERROR"}] ${job.errorMessage!}',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: AppColors.error,
                    ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'retries: ${job.retryCount}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (job.lastRetryAt != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    'last: ${_formatDateTime(job.lastRetryAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const Spacer(),
                if (isRetrying)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                    onPressed: canRetry ? onRetry : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, "0")}-${dt.day.toString().padLeft(2, "0")} '
        '${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
