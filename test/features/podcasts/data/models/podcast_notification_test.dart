import 'package:flutter_test/flutter_test.dart';
import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_notification.dart';

void main() {
  group('PodcastNotificationModel.fromJsonDto', () {
    test('parses pending Slack notification with default channel', () {
      final m = PodcastNotificationModel.fromJsonDto({
        'id': 'n1',
        'episode_id': 'e1',
        'channel': 'slack',
        'subject': 'Subj',
        'body': 'Body',
        'created_at': '2026-04-25T10:00:00Z',
        'updated_at': '2026-04-25T10:00:00Z',
      });
      expect(m.id, 'n1');
      expect(m.channel, 'slack');
      expect(m.recipient, isNull);
      expect(m.status, 'pending');
      expect(m.sentAt, isNull);
      expect(m.errorMessage, isNull);
    });

    test('parses sent SES notification with recipient + sent_at', () {
      final m = PodcastNotificationModel.fromJsonDto({
        'id': 'n1',
        'episode_id': 'e1',
        'channel': 'ses',
        'recipient': 'editor@tmz.com',
        'subject': 'Subj',
        'body': 'Body',
        'status': 'sent',
        'sent_at': '2026-04-25T10:01:00Z',
        'created_at': '2026-04-25T10:00:00Z',
        'updated_at': '2026-04-25T10:01:00Z',
      });
      expect(m.channel, 'ses');
      expect(m.recipient, 'editor@tmz.com');
      expect(m.status, 'sent');
      expect(m.sentAt, isNotNull);
    });

    test('parses failed notification with error_message', () {
      final m = PodcastNotificationModel.fromJsonDto({
        'id': 'n1',
        'episode_id': 'e1',
        'channel': 'slack',
        'subject': 'Subj',
        'body': 'Body',
        'status': 'failed',
        'error_message': 'Webhook returned 500',
        'created_at': '2026-04-25T10:00:00Z',
        'updated_at': '2026-04-25T10:01:00Z',
      });
      expect(m.status, 'failed');
      expect(m.errorMessage, 'Webhook returned 500');
    });

    test('toJsonDto omits null sent_at + error_message + recipient', () {
      final m = PodcastNotificationModel(
        id: 'n1',
        episodeId: 'e1',
        channel: 'slack',
        subject: 's',
        body: 'b',
        status: 'pending',
        createdAt: DateTime.utc(2026, 4, 25),
        updatedAt: DateTime.utc(2026, 4, 25),
      );
      final j = m.toJsonDto();
      expect(j.containsKey('sent_at'), isFalse);
      expect(j.containsKey('error_message'), isFalse);
      expect(j.containsKey('recipient'), isFalse);
    });

    test('copyWith advances pending -> sent', () {
      final m = PodcastNotificationModel(
        id: 'n1',
        episodeId: 'e1',
        channel: 'slack',
        subject: 's',
        body: 'b',
        status: 'pending',
        createdAt: DateTime.utc(2026, 4, 25),
        updatedAt: DateTime.utc(2026, 4, 25),
      );
      final p =
          m.copyWith(status: 'sent', sentAt: DateTime.utc(2026, 4, 25, 10));
      expect(p.status, 'sent');
      expect(p.sentAt, isNotNull);
      expect(m.status, 'pending');
    });
  });
}
