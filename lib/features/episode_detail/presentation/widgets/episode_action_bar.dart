import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../themes/app_theme.dart';
import '../../../podcasts/data/models/podcast_episode.dart';
import '../bloc/episode_detail_bloc.dart';
import 'edit_metadata_dialog.dart';
import 'episode_action_eligibility.dart';

/// Three-button action bar for EpisodeDetailView. Buttons are conditionally
/// rendered (absent, not space-reserving) per Pre-Approved Lock #1 and the
/// LSW-014 ReportedEpisodeCard convention.
class EpisodeActionBar extends StatelessWidget {
  final PodcastEpisodeModel episode;
  final bool isMutating;

  const EpisodeActionBar({
    super.key,
    required this.episode,
    this.isMutating = false,
  });

  @override
  Widget build(BuildContext context) {
    final showMarkReviewed = canMarkReviewed(episode);
    final showRequestClip = canRequestClip(episode);
    final showEditMetadata = canEditMetadata(episode);
    final anyAction = showMarkReviewed || showRequestClip || showEditMetadata;

    if (!anyAction) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceOverlay)),
      ),
      child: Row(
        children: [
          if (showMarkReviewed)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OutlinedButton.icon(
                key: const Key('episode_action_bar.mark_reviewed'),
                onPressed: isMutating
                    ? null
                    : () => context
                        .read<EpisodeDetailBloc>()
                        .add(MarkReviewedEvent(episode.id)),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Mark Reviewed'),
              ),
            ),
          if (showRequestClip)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OutlinedButton.icon(
                key: const Key('episode_action_bar.request_clip'),
                onPressed: isMutating
                    ? null
                    : () => context
                        .read<EpisodeDetailBloc>()
                        .add(RequestClipEvent(episode.id)),
                icon: const Icon(Icons.content_cut, size: 16),
                label: const Text('Request Clip'),
              ),
            ),
          if (showEditMetadata)
            OutlinedButton.icon(
              key: const Key('episode_action_bar.edit_metadata'),
              onPressed: isMutating ? null : () => _openEditDialog(context),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit Metadata'),
            ),
          const Spacer(),
          if (isMutating)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Future<void> _openEditDialog(BuildContext context) async {
    final detailBloc = context.read<EpisodeDetailBloc>();
    final patch = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => EditMetadataDialog(episode: episode),
    );
    if (patch != null && patch.isNotEmpty) {
      detailBloc.add(EditMetadataEvent(episodeId: episode.id, body: patch));
    }
  }
}
