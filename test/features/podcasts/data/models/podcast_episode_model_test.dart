import 'package:flutter_test/flutter_test.dart';
import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_episode.dart';

void main() {
  group('PodcastEpisodeModel.fromJsonDto', () {
    test('parses legacy 7-field payload with nullable WO-076 fields null',
        () {
      final model = PodcastEpisodeModel.fromJsonDto(const {
        'id': 'e1',
        'podcast_id': 'p1',
        'title': 'Episode 1',
        'source': 'rss',
        'source_url': 'http://example.com/e1',
        'published_at': '2026-04-20T12:00:00Z',
        'created_at': '2026-04-20T12:00:00Z',
      });

      expect(model.id, 'e1');
      expect(model.podcastId, 'p1');
      expect(model.title, 'Episode 1');
      expect(model.source, 'rss');
      expect(model.sourceUrl, 'http://example.com/e1');
      expect(model.publishedAt, DateTime.parse('2026-04-20T12:00:00Z'));
      expect(model.createdAt, DateTime.parse('2026-04-20T12:00:00Z'));

      expect(model.discoveredAt, isNull);
      expect(model.processingStatus, isNull);
      expect(model.transcriptStatus, isNull);
      expect(model.reviewedAt, isNull);
    });

    test('parses full reports payload with all 4 WO-076 fields populated',
        () {
      final model = PodcastEpisodeModel.fromJsonDto(const {
        'id': 'e2',
        'podcast_id': 'p1',
        'title': 'Episode 2',
        'source': 'rss',
        'created_at': '2026-04-20T12:00:00Z',
        'discovered_at': '2026-04-21T08:30:00Z',
        'processing_status': 'transcribed',
        'transcript_status': 'ready',
        'reviewed_at': '2026-04-21T09:00:00Z',
      });

      expect(model.discoveredAt,
          DateTime.parse('2026-04-21T08:30:00Z'));
      expect(model.processingStatus, 'transcribed');
      expect(model.transcriptStatus, 'ready');
      expect(model.reviewedAt, DateTime.parse('2026-04-21T09:00:00Z'));
    });

    test('props include all new fields for Equatable stability', () {
      final a = PodcastEpisodeModel(
        id: 'x',
        podcastId: 'p',
        title: 't',
        createdAt: DateTime(2026, 4, 20),
        processingStatus: 'detected',
      );
      final b = PodcastEpisodeModel(
        id: 'x',
        podcastId: 'p',
        title: 't',
        createdAt: DateTime(2026, 4, 20),
        processingStatus: 'reviewed',
      );
      expect(a, isNot(equals(b)));
    });
  });
}
