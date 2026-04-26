import 'package:flutter_test/flutter_test.dart';
import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_episode.dart';

void main() {
  group('PodcastEpisodeModel — back-compat with LSW-004 minimal payload', () {
    test('parses LSW-004 base fields with all WO-076/WO-077 fields null', () {
      final m = PodcastEpisodeModel.fromJsonDto({
        'id': 'e1',
        'podcast_id': 'p1',
        'title': 'Episode 1',
        'created_at': '2026-04-25T10:00:00Z',
      });
      expect(m.id, 'e1');
      expect(m.title, 'Episode 1');
      // WO-076 D2 fields default null
      expect(m.discoveredAt, isNull);
      expect(m.processingStatus, isNull);
      expect(m.transcriptStatus, isNull);
      expect(m.reviewedAt, isNull);
      // WO-077 D2 continuation fields default null
      expect(m.episodeDescription, isNull);
      expect(m.platformEpisodeUrl, isNull);
      expect(m.platformType, isNull);
      expect(m.guestNames, isNull);
      expect(m.headlineStatus, isNull);
      expect(m.notificationStatus, isNull);
    });
  });

  group('PodcastEpisodeModel — WO-077 D2 fields', () {
    test('parses 6 WO-077 fields when present', () {
      final m = PodcastEpisodeModel.fromJsonDto({
        'id': 'e1',
        'podcast_id': 'p1',
        'title': 'Episode 1',
        'created_at': '2026-04-25T10:00:00Z',
        'episode_description': 'A detailed description',
        'platform_episode_url': 'https://example.com/ep/1',
        'platform_type': 'spotify',
        'guest_names': ['Alice', 'Bob', 'Charlie'],
        'headline_status': 'approved',
        'notification_status': 'sent',
      });
      expect(m.episodeDescription, 'A detailed description');
      expect(m.platformEpisodeUrl, 'https://example.com/ep/1');
      expect(m.platformType, 'spotify');
      expect(m.guestNames, equals(['Alice', 'Bob', 'Charlie']));
      expect(m.headlineStatus, 'approved');
      expect(m.notificationStatus, 'sent');
    });

    test('guest_names: empty list parses as empty list (not null)', () {
      final m = PodcastEpisodeModel.fromJsonDto({
        'id': 'e1',
        'podcast_id': 'p1',
        'title': 'Episode 1',
        'created_at': '2026-04-25T10:00:00Z',
        'guest_names': [],
      });
      expect(m.guestNames, isNotNull);
      expect(m.guestNames, isEmpty);
    });

    test('guest_names: missing key parses as null', () {
      final m = PodcastEpisodeModel.fromJsonDto({
        'id': 'e1',
        'podcast_id': 'p1',
        'title': 'Episode 1',
        'created_at': '2026-04-25T10:00:00Z',
      });
      expect(m.guestNames, isNull);
    });

    test('copyWith updates only specified WO-077 fields', () {
      final m = PodcastEpisodeModel(
        id: 'e1',
        podcastId: 'p1',
        title: 't',
        createdAt: DateTime.utc(2026, 4, 25),
        episodeDescription: 'old',
        headlineStatus: 'pending',
      );
      final p = m.copyWith(
        episodeDescription: 'new',
        notificationStatus: 'sent',
      );
      expect(p.episodeDescription, 'new');
      expect(p.notificationStatus, 'sent');
      expect(p.headlineStatus, 'pending');
      expect(p.title, 't');
    });

    test('Equatable equality across all 17 fields', () {
      final a = PodcastEpisodeModel(
        id: 'e1',
        podcastId: 'p1',
        title: 't',
        createdAt: DateTime.utc(2026, 4, 25),
        guestNames: const ['A'],
      );
      final b = PodcastEpisodeModel(
        id: 'e1',
        podcastId: 'p1',
        title: 't',
        createdAt: DateTime.utc(2026, 4, 25),
        guestNames: const ['A'],
      );
      expect(a, equals(b));
    });
  });
}
