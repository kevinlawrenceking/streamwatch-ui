import 'package:flutter_test/flutter_test.dart';
import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_headline_candidate.dart';

void main() {
  group('PodcastHeadlineCandidateModel.fromJsonDto', () {
    test('parses required fields with defaults', () {
      final m = PodcastHeadlineCandidateModel.fromJsonDto({
        'id': 'h1',
        'episode_id': 'e1',
        'created_at': '2026-04-25T10:00:00Z',
        'updated_at': '2026-04-25T10:00:00Z',
      });
      expect(m.id, 'h1');
      expect(m.episodeId, 'e1');
      expect(m.status, 'pending');
      expect(m.text, isNull);
      expect(m.score, isNull);
      expect(m.approvedBy, isNull);
    });

    test('parses approved status with text + score + approvedBy', () {
      final m = PodcastHeadlineCandidateModel.fromJsonDto({
        'id': 'h1',
        'episode_id': 'e1',
        'text': 'Sample headline',
        'score': 0.87,
        'status': 'approved',
        'approved_by': 'editor-1',
        'created_at': '2026-04-25T10:00:00Z',
        'updated_at': '2026-04-25T10:05:00Z',
      });
      expect(m.text, 'Sample headline');
      expect(m.score, closeTo(0.87, 1e-9));
      expect(m.status, 'approved');
      expect(m.approvedBy, 'editor-1');
    });

    test('coerces int score to double', () {
      final m = PodcastHeadlineCandidateModel.fromJsonDto({
        'id': 'h1',
        'episode_id': 'e1',
        'score': 1,
        'created_at': '2026-04-25T10:00:00Z',
        'updated_at': '2026-04-25T10:00:00Z',
      });
      expect(m.score, 1.0);
    });

    test('toJsonDto round-trip preserves status', () {
      final m = PodcastHeadlineCandidateModel(
        id: 'h1',
        episodeId: 'e1',
        text: 't',
        status: 'rejected',
        createdAt: DateTime.utc(2026, 4, 25),
        updatedAt: DateTime.utc(2026, 4, 25),
      );
      final j = m.toJsonDto();
      expect(j['status'], 'rejected');
      expect(j['text'], 't');
    });

    test('copyWith updates status', () {
      final m = PodcastHeadlineCandidateModel(
        id: 'h1',
        episodeId: 'e1',
        status: 'pending',
        createdAt: DateTime.utc(2026, 4, 25),
        updatedAt: DateTime.utc(2026, 4, 25),
      );
      final p = m.copyWith(status: 'approved');
      expect(p.status, 'approved');
      expect(m.status, 'pending');
    });
  });
}
