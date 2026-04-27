import 'package:flutter_test/flutter_test.dart';

import 'package:streamwatch_frontend/features/jobs/data/models/detection_action.dart';

void main() {
  group('DetectionAction.fromJsonDto', () {
    test('parses base fields', () {
      final action = DetectionAction.fromJsonDto({
        'id': 'a-1',
        'run_id': 'r-1',
        'sequence_index': 0,
        'action_type': 'transcript_fetched',
        'created_at': '2026-04-25T12:00:00Z',
      });
      expect(action.id, 'a-1');
      expect(action.runId, 'r-1');
      expect(action.sequenceIndex, 0);
      expect(action.actionType, 'transcript_fetched');
      expect(action.payloadJson, isNull);
    });

    test('parses payload_json as Map; non-Map yields null', () {
      final withMap = DetectionAction.fromJsonDto({
        'id': 'a-2',
        'run_id': 'r-1',
        'sequence_index': 1,
        'action_type': 'celebrity_match',
        'payload_json': {'name': 'Alice', 'confidence': 0.92},
        'created_at': '2026-04-25T12:00:00Z',
      });
      expect(withMap.payloadJson, isNotNull);
      expect(withMap.payloadJson!['name'], 'Alice');

      final noPayload = DetectionAction.fromJsonDto({
        'id': 'a-3',
        'run_id': 'r-1',
        'sequence_index': 2,
        'action_type': 'noop',
        'payload_json': null,
        'created_at': '2026-04-25T12:00:00Z',
      });
      expect(noPayload.payloadJson, isNull);
    });

    test('sequence_index ordering preserved by caller (server pre-sorts)', () {
      // Per KB section 18g.2 amendment 7 the server returns rows in
      // sequence_index ASC; this test asserts our parsed objects preserve
      // the index for caller-side verification.
      final list = [
        {
          'id': 'a-1',
          'run_id': 'r-1',
          'sequence_index': 0,
          'action_type': 'a',
          'created_at': '2026-04-25T12:00:00Z',
        },
        {
          'id': 'a-2',
          'run_id': 'r-1',
          'sequence_index': 1,
          'action_type': 'b',
          'created_at': '2026-04-25T12:00:01Z',
        },
        {
          'id': 'a-3',
          'run_id': 'r-1',
          'sequence_index': 2,
          'action_type': 'c',
          'created_at': '2026-04-25T12:00:02Z',
        },
      ].map(DetectionAction.fromJsonDto).toList();
      expect(list.map((a) => a.sequenceIndex).toList(), [0, 1, 2]);
    });
  });
}
