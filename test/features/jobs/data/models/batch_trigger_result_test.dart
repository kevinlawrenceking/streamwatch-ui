import 'package:flutter_test/flutter_test.dart';

import 'package:streamwatch_frontend/features/jobs/data/models/batch_trigger_result.dart';

void main() {
  group('BatchTriggerItemResult', () {
    test('success row: status int = 202, runId populated, no error_code', () {
      final r = BatchTriggerItemResult.fromJsonDto({
        'episode_id': 'ep-1',
        'status': 202,
        'run_id': 'r-xyz',
      });
      expect(r.status, 202);
      expect(r.isSuccess, true);
      expect(r.isConflict, false);
      expect(r.runId, 'r-xyz');
      expect(r.errorCode, isNull);
    });

    test('409 row: status int = 409, errorCode = ALREADY_ACTIVE', () {
      final r = BatchTriggerItemResult.fromJsonDto({
        'episode_id': 'ep-2',
        'status': 409,
        'error_code': 'ALREADY_ACTIVE',
      });
      expect(r.status, 409);
      expect(r.isConflict, true);
      expect(r.isSuccess, false);
      expect(r.errorCode, 'ALREADY_ACTIVE');
      expect(r.runId, isNull);
    });

    test('404 row: status int = 404, errorCode = EPISODE_NOT_FOUND', () {
      final r = BatchTriggerItemResult.fromJsonDto({
        'episode_id': 'ep-3',
        'status': 404,
        'error_code': 'EPISODE_NOT_FOUND',
      });
      expect(r.status, 404);
      expect(r.isNotFound, true);
      expect(r.errorCode, 'EPISODE_NOT_FOUND');
    });
  });
}
