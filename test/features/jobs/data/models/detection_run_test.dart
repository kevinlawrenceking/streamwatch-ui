import 'package:flutter_test/flutter_test.dart';

import 'package:streamwatch_frontend/features/jobs/data/models/detection_run.dart';

void main() {
  group('DetectionRun.fromJsonDto', () {
    test('parses full JSON', () {
      final run = DetectionRun.fromJsonDto({
        'id': 'r-1',
        'episode_id': 'ep-1',
        'status': 'queued',
        'triggered_by': 'u-1',
        'created_at': '2026-04-25T12:00:00Z',
        'updated_at': '2026-04-25T12:00:00Z',
      });
      expect(run.id, 'r-1');
      expect(run.episodeId, 'ep-1');
      expect(run.status, 'queued');
      expect(run.isActive, true);
      expect(run.isSucceeded, false);
    });

    test('status flips reflected by helpers', () {
      final base = DetectionRun(
        id: 'r-2',
        episodeId: 'ep-2',
        status: 'queued',
        createdAt: DateTime.utc(2026, 4, 25),
        updatedAt: DateTime.utc(2026, 4, 25),
      );
      expect(base.isActive, true);
      final succeeded = base.copyWith(status: 'succeeded');
      expect(succeeded.isSucceeded, true);
      expect(succeeded.isActive, false);
      final failed = base.copyWith(status: 'failed');
      expect(failed.isFailed, true);
    });

    test('copyWith preserves untouched fields', () {
      final base = DetectionRun(
        id: 'r-3',
        episodeId: 'ep-3',
        status: 'running',
        startedAt: DateTime.utc(2026, 4, 25, 12),
        createdAt: DateTime.utc(2026, 4, 25),
        updatedAt: DateTime.utc(2026, 4, 25),
      );
      final newer = base.copyWith(status: 'succeeded');
      expect(newer.startedAt, base.startedAt);
    });

    test('Equatable equality based on field values', () {
      final a = DetectionRun(
        id: 'r-4',
        episodeId: 'ep-4',
        status: 'queued',
        createdAt: DateTime.utc(2026, 4, 25),
        updatedAt: DateTime.utc(2026, 4, 25),
      );
      final b = DetectionRun(
        id: 'r-4',
        episodeId: 'ep-4',
        status: 'queued',
        createdAt: DateTime.utc(2026, 4, 25),
        updatedAt: DateTime.utc(2026, 4, 25),
      );
      expect(a, equals(b));
    });
  });
}
