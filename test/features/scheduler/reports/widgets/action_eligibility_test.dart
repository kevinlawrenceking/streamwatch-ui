import 'package:flutter_test/flutter_test.dart';
import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_episode.dart';
import 'package:streamwatch_frontend/features/scheduler/reports/widgets/action_eligibility.dart';

PodcastEpisodeModel ep({
  String? transcript,
  String? processing,
  DateTime? reviewedAt,
}) {
  return PodcastEpisodeModel(
    id: 'e',
    podcastId: 'p',
    title: 't',
    createdAt: DateTime(2026, 4, 20),
    transcriptStatus: transcript,
    processingStatus: processing,
    reviewedAt: reviewedAt,
  );
}

void main() {
  group('canMarkReviewed', () {
    test('hidden for transcript-pending regardless of state', () {
      expect(
        canMarkReviewed(
          'transcript-pending',
          ep(transcript: 'ready', reviewedAt: null),
        ),
        isFalse,
      );
    });

    test('hidden for pending-clip-request regardless of state', () {
      expect(
        canMarkReviewed(
          'pending-clip-request',
          ep(transcript: 'ready', reviewedAt: null),
        ),
        isFalse,
      );
    });

    test('shown for pending-review when reviewed_at null + transcript ready',
        () {
      expect(
        canMarkReviewed(
          'pending-review',
          ep(transcript: 'ready', reviewedAt: null),
        ),
        isTrue,
      );
    });

    test('hidden for pending-review if already reviewed (defensive gate)', () {
      expect(
        canMarkReviewed(
          'pending-review',
          ep(transcript: 'ready', reviewedAt: DateTime(2026, 4, 21)),
        ),
        isFalse,
      );
    });

    test('shown conditionally in recent + transcript=ready + not reviewed',
        () {
      expect(
        canMarkReviewed(
          'recent',
          ep(transcript: 'ready', reviewedAt: null),
        ),
        isTrue,
      );
    });

    test('hidden in recent when transcript not ready', () {
      expect(
        canMarkReviewed(
          'recent',
          ep(transcript: 'pending', reviewedAt: null),
        ),
        isFalse,
      );
    });

    test('hidden in recent when already reviewed', () {
      expect(
        canMarkReviewed(
          'recent',
          ep(transcript: 'ready', reviewedAt: DateTime(2026, 4, 21)),
        ),
        isFalse,
      );
    });

    test('same condition applies to headline-ready', () {
      expect(
        canMarkReviewed(
          'headline-ready',
          ep(transcript: 'ready', reviewedAt: null),
        ),
        isTrue,
      );
      expect(
        canMarkReviewed(
          'headline-ready',
          ep(transcript: 'ready', reviewedAt: DateTime(2026, 4, 21)),
        ),
        isFalse,
      );
    });
  });

  group('canRequestClip', () {
    test('hidden for transcript-pending and pending-clip-request', () {
      expect(canRequestClip('transcript-pending', ep(processing: 'detected')),
          isFalse);
      expect(
          canRequestClip('pending-clip-request', ep(processing: 'detected')),
          isFalse);
    });

    test('hidden for pending-review per E6 matrix', () {
      expect(
        canRequestClip('pending-review', ep(processing: 'reviewed')),
        isFalse,
      );
    });

    test('shown in recent/headline-ready when status pre-clip_requested', () {
      for (final slug in ['recent', 'headline-ready']) {
        for (final s in ['detected', 'transcribed', 'reviewed']) {
          expect(
            canRequestClip(slug, ep(processing: s)),
            isTrue,
            reason: '$slug + $s should be eligible',
          );
        }
        expect(
          canRequestClip(slug, ep(processing: null)),
          isTrue,
          reason: '$slug + null status treated as pre-clip_requested',
        );
      }
    });

    test('hidden in recent/headline-ready once clip_requested or completed',
        () {
      for (final slug in ['recent', 'headline-ready']) {
        expect(canRequestClip(slug, ep(processing: 'clip_requested')),
            isFalse);
        expect(canRequestClip(slug, ep(processing: 'completed')), isFalse);
      }
    });
  });
}
