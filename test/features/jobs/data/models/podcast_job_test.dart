import 'package:flutter_test/flutter_test.dart';

import 'package:streamwatch_frontend/features/jobs/data/models/podcast_job.dart';

void main() {
  group('PodcastJob.fromJsonDto', () {
    test('parses base fields', () {
      final job = PodcastJob.fromJsonDto({
        'job_id': 'j-1',
        'status': 'failed',
        'created_at': '2026-04-20T10:00:00Z',
        'error_code': 'TRANSCRIPT_FAILED',
        'error_message': 'whisper timeout',
      });
      expect(job.jobId, 'j-1');
      expect(job.status, 'failed');
      expect(job.errorCode, 'TRANSCRIPT_FAILED');
      expect(job.retryCount, 0);
    });

    test('parses retry bookkeeping fields per KB section 18g.5', () {
      final job = PodcastJob.fromJsonDto({
        'job_id': 'j-2',
        'status': 'queued',
        'created_at': '2026-04-20T10:00:00Z',
        'retry_count': 3,
        'last_retry_at': '2026-04-25T12:00:00Z',
        'last_retry_by': 'u-7',
      });
      expect(job.retryCount, 3);
      expect(job.lastRetryAt, DateTime.utc(2026, 4, 25, 12));
      expect(job.lastRetryBy, 'u-7');
    });

    test('copyWith flips status without losing other fields', () {
      final job = PodcastJob(
        jobId: 'j-3',
        status: 'failed',
        retryCount: 1,
        createdAt: DateTime.utc(2026, 4, 20),
      );
      final queued = job.copyWith(status: 'queued', errorCode: null);
      expect(queued.status, 'queued');
      expect(queued.retryCount, 1);
    });

    test('Equatable equality based on field values', () {
      final a = PodcastJob(
        jobId: 'j-4',
        status: 'queued',
        createdAt: DateTime.utc(2026, 4, 20),
      );
      final b = PodcastJob(
        jobId: 'j-4',
        status: 'queued',
        createdAt: DateTime.utc(2026, 4, 20),
      );
      expect(a, equals(b));
    });
  });
}
