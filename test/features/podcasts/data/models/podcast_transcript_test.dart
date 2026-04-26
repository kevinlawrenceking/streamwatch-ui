import 'package:flutter_test/flutter_test.dart';
import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_transcript.dart';

void main() {
  group('PodcastTranscriptModel.fromJsonDto', () {
    test('parses minimum required fields', () {
      final m = PodcastTranscriptModel.fromJsonDto({
        'id': 't1',
        'episode_id': 'e1',
        'variant': 'raw',
        'source_type': 'auto',
        'created_at': '2026-04-25T10:00:00Z',
        'updated_at': '2026-04-25T10:00:00Z',
      });
      expect(m.id, 't1');
      expect(m.episodeId, 'e1');
      expect(m.variant, 'raw');
      expect(m.sourceType, 'auto');
      expect(m.isPrimary, isFalse);
      expect(m.text, isNull);
      expect(m.transcriptJson, isNull);
      expect(m.languageCode, isNull);
    });

    test('parses all optional fields when present', () {
      final m = PodcastTranscriptModel.fromJsonDto({
        'id': 't1',
        'episode_id': 'e1',
        'variant': 'edited',
        'source_type': 'manual',
        'text': 'Lorem ipsum',
        'transcript_json': {'segments': []},
        'is_primary': true,
        'language_code': 'en-US',
        'created_at': '2026-04-25T10:00:00Z',
        'updated_at': '2026-04-25T10:00:00Z',
      });
      expect(m.text, 'Lorem ipsum');
      expect(m.transcriptJson, {'segments': []});
      expect(m.isPrimary, isTrue);
      expect(m.languageCode, 'en-US');
    });

    test('toJsonDto omits null optional fields', () {
      final m = PodcastTranscriptModel(
        id: 't1',
        episodeId: 'e1',
        variant: 'raw',
        sourceType: 'auto',
        createdAt: DateTime.utc(2026, 4, 25, 10),
        updatedAt: DateTime.utc(2026, 4, 25, 10),
      );
      final j = m.toJsonDto();
      expect(j.containsKey('text'), isFalse);
      expect(j.containsKey('transcript_json'), isFalse);
      expect(j.containsKey('language_code'), isFalse);
      expect(j['is_primary'], isFalse);
    });

    test('copyWith flips is_primary', () {
      final m = PodcastTranscriptModel(
        id: 't1',
        episodeId: 'e1',
        variant: 'raw',
        sourceType: 'auto',
        createdAt: DateTime.utc(2026, 4, 25),
        updatedAt: DateTime.utc(2026, 4, 25),
      );
      final p = m.copyWith(isPrimary: true);
      expect(m.isPrimary, isFalse);
      expect(p.isPrimary, isTrue);
      expect(p.id, m.id);
    });

    test('Equatable equality on identical fields', () {
      final a = PodcastTranscriptModel(
        id: 't1',
        episodeId: 'e1',
        variant: 'raw',
        sourceType: 'auto',
        createdAt: DateTime.utc(2026, 4, 25),
        updatedAt: DateTime.utc(2026, 4, 25),
      );
      final b = PodcastTranscriptModel(
        id: 't1',
        episodeId: 'e1',
        variant: 'raw',
        sourceType: 'auto',
        createdAt: DateTime.utc(2026, 4, 25),
        updatedAt: DateTime.utc(2026, 4, 25),
      );
      expect(a, equals(b));
    });
  });
}
