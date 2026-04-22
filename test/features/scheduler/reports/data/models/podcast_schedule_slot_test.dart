import 'package:flutter_test/flutter_test.dart';
import 'package:streamwatch_frontend/features/scheduler/reports/data/models/podcast_schedule_slot.dart';

void main() {
  group('PodcastScheduleSlot.fromJsonDto', () {
    test('parses all 17 fields', () {
      final slot = PodcastScheduleSlot.fromJsonDto(const {
        'id': 's1',
        'podcast_id': 'p1',
        'day_of_week': 'Monday',
        'start_time_pt': '06:30:00',
        'time_text_raw': 'Mon 6:30a PT',
        'source': 'csv_import',
        'time_precision': 'exact',
        'schedule_confidence': 'high',
        'release_window_start': '06:00:00',
        'release_window_end': '07:00:00',
        'check_before_minutes': 15,
        'lateness_grace_minutes': 10,
        'priority_rank': 1,
        'is_active': true,
        'notes': 'primary',
        'created_at': '2026-04-20T12:00:00Z',
        'updated_at': '2026-04-20T12:00:00Z',
      });

      expect(slot.id, 's1');
      expect(slot.podcastId, 'p1');
      expect(slot.dayOfWeek, 'Monday');
      expect(slot.startTimePt, '06:30:00');
      expect(slot.source, 'csv_import');
      expect(slot.scheduleConfidence, 'high');
      expect(slot.checkBeforeMinutes, 15);
      expect(slot.latenessGraceMinutes, 10);
      expect(slot.priorityRank, 1);
      expect(slot.isActive, true);
      expect(slot.notes, 'primary');
    });

    test('omitempty-absent nullable fields parse as null', () {
      final slot = PodcastScheduleSlot.fromJsonDto(const {
        'id': 's2',
        'podcast_id': 'p2',
        'source': 'manual',
        'is_active': true,
        'created_at': '2026-04-20T12:00:00Z',
        'updated_at': '2026-04-20T12:00:00Z',
      });

      expect(slot.dayOfWeek, isNull);
      expect(slot.startTimePt, isNull);
      expect(slot.scheduleConfidence, isNull);
      expect(slot.checkBeforeMinutes, isNull);
      expect(slot.latenessGraceMinutes, isNull);
      expect(slot.priorityRank, isNull);
      expect(slot.notes, isNull);
    });

    test('Equatable treats identical slots as equal', () {
      final a = PodcastScheduleSlot.fromJsonDto(const {
        'id': 's3',
        'podcast_id': 'p3',
        'source': 'rss',
        'is_active': false,
        'created_at': '2026-04-20T12:00:00Z',
        'updated_at': '2026-04-20T12:00:00Z',
      });
      final b = PodcastScheduleSlot.fromJsonDto(const {
        'id': 's3',
        'podcast_id': 'p3',
        'source': 'rss',
        'is_active': false,
        'created_at': '2026-04-20T12:00:00Z',
        'updated_at': '2026-04-20T12:00:00Z',
      });
      expect(a, equals(b));
    });
  });
}
