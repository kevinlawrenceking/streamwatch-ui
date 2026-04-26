import 'package:flutter_test/flutter_test.dart';
import 'package:streamwatch_frontend/features/episode_detail/presentation/widgets/episode_action_eligibility.dart';
import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_episode.dart';

PodcastEpisodeModel _ep({
  String? transcriptStatus,
  String? processingStatus,
  DateTime? reviewedAt,
}) {
  return PodcastEpisodeModel(
    id: 'e',
    podcastId: 'p',
    title: 't',
    createdAt: DateTime(2026, 4, 25),
    transcriptStatus: transcriptStatus,
    processingStatus: processingStatus,
    reviewedAt: reviewedAt,
  );
}

void main() {
  group('canMarkReviewed (reportKey-free)', () {
    test('shown when reviewedAt null + transcriptStatus ready', () {
      expect(
        canMarkReviewed(_ep(transcriptStatus: 'ready')),
        isTrue,
      );
    });

    test('hidden when already reviewed', () {
      expect(
        canMarkReviewed(
            _ep(transcriptStatus: 'ready', reviewedAt: DateTime(2026, 4, 24))),
        isFalse,
      );
    });

    test('hidden when transcriptStatus not ready', () {
      expect(canMarkReviewed(_ep(transcriptStatus: 'pending')), isFalse);
      expect(canMarkReviewed(_ep(transcriptStatus: 'completed')), isFalse);
      expect(canMarkReviewed(_ep(transcriptStatus: null)), isFalse);
    });

    test('hidden when transcriptStatus ready but reviewedAt set', () {
      expect(
        canMarkReviewed(
            _ep(transcriptStatus: 'ready', reviewedAt: DateTime(2026, 4, 25))),
        isFalse,
      );
    });
  });

  group('canRequestClip (reportKey-free)', () {
    test('shown for pre-clip_requested statuses', () {
      for (final s in const ['detected', 'transcribed', 'reviewed']) {
        expect(
          canRequestClip(_ep(processingStatus: s)),
          isTrue,
          reason: 'processing_status=$s should allow Request Clip',
        );
      }
    });

    test('shown for null processingStatus (treated as earliest)', () {
      expect(canRequestClip(_ep()), isTrue);
    });

    test('hidden once clip_requested or completed', () {
      expect(canRequestClip(_ep(processingStatus: 'clip_requested')), isFalse);
      expect(canRequestClip(_ep(processingStatus: 'completed')), isFalse);
    });

    test('hidden for failed', () {
      expect(canRequestClip(_ep(processingStatus: 'failed')), isFalse);
    });
  });

  group('canEditMetadata', () {
    test('always true regardless of episode state', () {
      expect(canEditMetadata(_ep()), isTrue);
      expect(
        canEditMetadata(_ep(
            transcriptStatus: 'ready',
            reviewedAt: DateTime(2026, 4, 25),
            processingStatus: 'completed')),
        isTrue,
      );
    });
  });
}
