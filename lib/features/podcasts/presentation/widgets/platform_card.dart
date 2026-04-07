import 'package:flutter/material.dart';

import '../../../../themes/app_theme.dart';
import '../../data/models/podcast_platform.dart';

/// Card widget for displaying a podcast platform link.
class PlatformCard extends StatelessWidget {
  final PodcastPlatformModel platform;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PlatformCard({
    super.key,
    required this.platform,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              _getPlatformIcon(platform.platformName),
              color: AppColors.tmzRed,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platform.platformName,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    platform.platformUrl,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: AppColors.textDim,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPlatformIcon(String name) {
    switch (name.toLowerCase()) {
      case 'spotify':
        return Icons.music_note;
      case 'apple podcasts':
      case 'apple':
        return Icons.apple;
      case 'youtube':
        return Icons.play_circle;
      case 'rss':
        return Icons.rss_feed;
      default:
        return Icons.link;
    }
  }
}
