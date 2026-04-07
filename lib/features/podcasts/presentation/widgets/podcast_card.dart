import 'package:flutter/material.dart';

import '../../../../themes/app_theme.dart';
import '../../data/models/podcast.dart';

/// Card widget for displaying a podcast in the list view.
class PodcastCard extends StatelessWidget {
  final PodcastModel podcast;
  final VoidCallback? onTap;
  final VoidCallback? onDeactivate;
  final VoidCallback? onActivate;

  const PodcastCard({
    super.key,
    required this.podcast,
    this.onTap,
    this.onDeactivate,
    this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.podcasts,
                color: podcast.isActive
                    ? AppColors.success
                    : AppColors.textGhost,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      podcast.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (podcast.description != null &&
                        podcast.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        podcast.description!,
                        style: Theme.of(context).textTheme.bodySmall!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Updated ${_formatDate(podcast.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: AppColors.textDim,
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
              ),
              _ActiveBadge(isActive: podcast.isActive),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'deactivate') onDeactivate?.call();
                  if (value == 'activate') onActivate?.call();
                },
                itemBuilder: (context) => [
                  if (podcast.isActive)
                    const PopupMenuItem<String>(
                      value: 'deactivate',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.pause_circle_outline),
                        title: Text('Deactivate'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                  else
                    const PopupMenuItem<String>(
                      value: 'activate',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.play_circle_outline),
                        title: Text('Activate'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _ActiveBadge extends StatelessWidget {
  final bool isActive;

  const _ActiveBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.textGhost;
    final label = isActive ? 'ACTIVE' : 'INACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
      ),
    );
  }
}
