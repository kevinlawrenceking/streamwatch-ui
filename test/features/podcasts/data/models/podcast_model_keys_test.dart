import 'package:flutter_test/flutter_test.dart';

import 'package:streamwatch_frontend/features/podcasts/data/models/podcast.dart';

// WO-112-RED / LSW-VER-T2 — Pattern A persistence guard for podcast Info edit (#10).
// Backend UpdatePodcastRequest has Notes (`json:"notes,omitempty"`) but no
// Description field. Pre-fix the form/model wrote `description`, silently dropped
// by Go json.Decode. Post-fix the form and PodcastModel.toJsonDto write `notes`,
// and fromJsonDto reads `notes` first with `description` as a backwards-tolerant
// fallback (mirrors the start_time/start_time_pt fallback in PodcastScheduleModel).

PodcastModel _model({String? description}) => PodcastModel(
      id: 'p-1',
      name: 'Test Podcast',
      description: description,
      isActive: true,
      createdAt: DateTime.utc(2026, 5, 1),
      updatedAt: DateTime.utc(2026, 5, 2),
    );

void main() {
  group('PodcastModel.toJsonDto — Pattern A write-path guard', () {
    test('emits "notes" not "description" when description is present', () {
      final json = _model(description: 'hello').toJsonDto();
      expect(json.containsKey('notes'), isTrue);
      expect(json.containsKey('description'), isFalse);
      expect(json['notes'], 'hello');
    });

    test('omits the notes key entirely when description is null', () {
      final json = _model().toJsonDto();
      expect(json.containsKey('notes'), isFalse);
      expect(json.containsKey('description'), isFalse);
    });
  });

  group('PodcastModel.fromJsonDto — Pattern A read-path guard', () {
    Map<String, dynamic> baseJson() => {
          'id': 'p-1',
          'name': 'Test Podcast',
          'is_active': true,
          'created_at': '2026-05-01T00:00:00.000Z',
          'updated_at': '2026-05-02T00:00:00.000Z',
        };

    test('prefers "notes" when both notes and description are present', () {
      final json = baseJson()
        ..addAll({'notes': 'from notes', 'description': 'from description'});
      expect(PodcastModel.fromJsonDto(json).description, 'from notes');
    });

    test('reads "notes" when only notes is present (post-fix backend shape)',
        () {
      final json = baseJson()..addAll({'notes': 'from notes'});
      expect(PodcastModel.fromJsonDto(json).description, 'from notes');
    });

    test('falls back to "description" when only description is present', () {
      final json = baseJson()..addAll({'description': 'legacy'});
      expect(PodcastModel.fromJsonDto(json).description, 'legacy');
    });

    test('returns null when neither key is present', () {
      expect(PodcastModel.fromJsonDto(baseJson()).description, isNull);
    });

    test('round-trip via notes preserves the description text', () {
      final saved = _model(description: 'round-trip text').toJsonDto();
      // Simulate the backend echoing back with the notes key populated.
      final fetched = PodcastModel.fromJsonDto({
        ...baseJson(),
        ...saved,
      });
      expect(fetched.description, 'round-trip text');
    });
  });
}
