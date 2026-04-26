import 'package:flutter/material.dart';

import '../../../../themes/app_theme.dart';
import '../../../podcasts/data/models/podcast_transcript.dart';

/// Single-row presentation for a PodcastTranscriptModel. Set-Primary +
/// Delete inline actions. Edit (PATCH) is reserved for a future expand-row
/// flow; not included in this WO.
class TranscriptCard extends StatelessWidget {
  final PodcastTranscriptModel transcript;
  final bool inFlight;
  final VoidCallback? onSetPrimary;
  final VoidCallback? onDelete;

  const TranscriptCard({
    super.key,
    required this.transcript,
    this.inFlight = false,
    this.onSetPrimary,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        transcript.variant,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      if (transcript.isPrimary)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.info,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PRIMARY',
                            style:
                                Theme.of(context).textTheme.bodySmall!.copyWith(
                                      color: AppColors.textMax,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'source: ${transcript.sourceType}'
                    '${transcript.languageCode != null ? '  -  ${transcript.languageCode}' : ''}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: AppColors.textDim, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (!transcript.isPrimary)
              IconButton(
                key: Key('transcript_card.set_primary.${transcript.id}'),
                tooltip: 'Set primary',
                onPressed: inFlight ? null : onSetPrimary,
                icon: const Icon(Icons.push_pin_outlined, size: 18),
              ),
            IconButton(
              key: Key('transcript_card.delete.${transcript.id}'),
              tooltip: 'Delete',
              onPressed: inFlight ? null : onDelete,
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }
}
