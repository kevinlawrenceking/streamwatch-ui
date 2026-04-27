import 'package:flutter/material.dart';

import '../../../../themes/app_theme.dart';
import '../../data/models/guest_watchlist_entry.dart';

/// Single row card for a guest watchlist entry.
///
/// AC-6: terminal entries (matched / expired) render read-only --
/// neither the Edit nor Change Status button is shown.
class WatchlistEntryCard extends StatelessWidget {
  final PodcastGuestWatchlistEntry entry;
  final VoidCallback? onEdit;
  final VoidCallback? onChangeStatus;

  const WatchlistEntryCard({
    super.key,
    required this.entry,
    this.onEdit,
    this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    final neutralColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final statusColor = entry.isMatched
        ? AppColors.success
        : entry.isExpired
            ? AppColors.error
            : neutralColor;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    entry.guestName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                _StatusBadge(label: entry.status, color: statusColor),
              ],
            ),
            if (entry.aliases.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'aka ${entry.aliases.join(", ")}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (entry.reason != null) ...[
              const SizedBox(height: 4),
              Text(
                entry.reason!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'priority: ${entry.priority}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                Text(
                  'added ${_formatDate(entry.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                if (!entry.isTerminal) ...[
                  TextButton(
                    onPressed: onEdit,
                    child: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: onChangeStatus,
                    child: const Text('Change Status'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, "0")}-${dt.day.toString().padLeft(2, "0")}';
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
