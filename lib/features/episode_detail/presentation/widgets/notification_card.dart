import 'package:flutter/material.dart';

import '../../../../themes/app_theme.dart';
import '../../../podcasts/data/models/podcast_notification.dart';

/// Single-row presentation for a PodcastNotificationModel. Send + Delete
/// inline actions; channel icon + recipient + status badge.
class NotificationCard extends StatelessWidget {
  final PodcastNotificationModel notification;
  final bool inFlight;
  final VoidCallback? onSend;
  final VoidCallback? onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    this.inFlight = false,
    this.onSend,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = notification.status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  notification.channel == 'slack' ? Icons.tag : Icons.email,
                  size: 18,
                  color: AppColors.textDim,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notification.subject,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _statusBadge(context),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'to: ${notification.recipient ?? '(default channel)'}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: AppColors.textDim, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Spacer(),
                if (isPending)
                  TextButton.icon(
                    key: Key('notification_card.send.${notification.id}'),
                    onPressed: inFlight ? null : onSend,
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Send'),
                  ),
                IconButton(
                  key: Key('notification_card.delete.${notification.id}'),
                  tooltip: 'Delete',
                  onPressed: inFlight ? null : onDelete,
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
    final color = switch (notification.status) {
      'sent' => AppColors.success,
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
        notification.status.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: AppColors.textMax,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
      ),
    );
  }
}
