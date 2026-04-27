import 'package:flutter_test/flutter_test.dart';

import 'package:streamwatch_frontend/features/watchlist/data/models/guest_watchlist_entry.dart';

void main() {
  group('PodcastGuestWatchlistEntry.fromJsonDto', () {
    test('parses full JSON with all 12 fields', () {
      final entry = PodcastGuestWatchlistEntry.fromJsonDto({
        'id': 'wl-1',
        'guest_name': 'Alice',
        'aliases': ['Al', 'A.'],
        'reason': 'recurring guest',
        'priority': 'high',
        'status': 'matched',
        'matched_episode_id': 'ep-99',
        'matched_at': '2026-04-25T12:00:00Z',
        'expires_at': null,
        'created_by': 'u-1',
        'created_at': '2026-04-20T10:00:00Z',
        'updated_at': '2026-04-25T12:00:00Z',
      });
      expect(entry.id, 'wl-1');
      expect(entry.guestName, 'Alice');
      expect(entry.aliases, ['Al', 'A.']);
      expect(entry.priority, 'high');
      expect(entry.status, 'matched');
      expect(entry.matchedEpisodeId, 'ep-99');
      expect(entry.isMatched, true);
      expect(entry.isTerminal, true);
    });

    test('omits-null fields default to null and aliases default to empty', () {
      final entry = PodcastGuestWatchlistEntry.fromJsonDto({
        'id': 'wl-2',
        'guest_name': 'Bob',
        'created_at': '2026-04-20T10:00:00Z',
        'updated_at': '2026-04-20T10:00:00Z',
      });
      expect(entry.aliases, isEmpty);
      expect(entry.reason, isNull);
      expect(entry.priority, 'medium'); // default
      expect(entry.status, 'active'); // default
      expect(entry.matchedEpisodeId, isNull);
      expect(entry.isActive, true);
      expect(entry.isTerminal, false);
    });

    test('toJsonDto round-trips and omits null fields', () {
      final entry = PodcastGuestWatchlistEntry(
        id: 'wl-3',
        guestName: 'Carol',
        aliases: const [],
        priority: 'low',
        status: 'active',
        createdAt: DateTime.utc(2026, 4, 20),
        updatedAt: DateTime.utc(2026, 4, 20),
      );
      final json = entry.toJsonDto();
      expect(json.containsKey('reason'), false);
      expect(json.containsKey('matched_episode_id'), false);
      expect(json['priority'], 'low');
    });

    test('copyWith mutates a single field', () {
      final entry = PodcastGuestWatchlistEntry(
        id: 'wl-4',
        guestName: 'Dave',
        aliases: const [],
        priority: 'medium',
        status: 'active',
        createdAt: DateTime.utc(2026, 4, 20),
        updatedAt: DateTime.utc(2026, 4, 20),
      );
      final flipped = entry.copyWith(status: 'expired');
      expect(flipped.status, 'expired');
      expect(flipped.isExpired, true);
      expect(flipped.guestName, 'Dave');
    });

    test('Equatable equality based on field values', () {
      final a = PodcastGuestWatchlistEntry(
        id: 'wl-5',
        guestName: 'Eve',
        aliases: const ['E'],
        priority: 'medium',
        status: 'active',
        createdAt: DateTime.utc(2026, 4, 20),
        updatedAt: DateTime.utc(2026, 4, 20),
      );
      final b = PodcastGuestWatchlistEntry(
        id: 'wl-5',
        guestName: 'Eve',
        aliases: const ['E'],
        priority: 'medium',
        status: 'active',
        createdAt: DateTime.utc(2026, 4, 20),
        updatedAt: DateTime.utc(2026, 4, 20),
      );
      expect(a, equals(b));
    });
  });
}
