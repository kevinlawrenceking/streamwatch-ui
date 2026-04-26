import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/features/episode_detail/presentation/bloc/episode_notifications_bloc.dart';
import 'package:streamwatch_frontend/features/podcasts/data/data_sources/podcast_data_source.dart';
import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_notification.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockPodcastDataSource extends Mock implements IPodcastDataSource {}

PodcastNotificationModel _n(String id, {String status = 'pending'}) =>
    PodcastNotificationModel(
      id: id,
      episodeId: 'e1',
      channel: 'slack',
      subject: 'subj',
      body: 'body',
      status: status,
      createdAt: DateTime.utc(2026, 4, 25),
      updatedAt: DateTime.utc(2026, 4, 25),
    );

void main() {
  late MockPodcastDataSource ds;
  setUp(() {
    ds = MockPodcastDataSource();
  });
  EpisodeNotificationsBloc build() => EpisodeNotificationsBloc(dataSource: ds);

  group('load', () {
    blocTest<EpisodeNotificationsBloc, EpisodeNotificationsState>(
      'happy',
      build: () {
        when(() => ds.listNotifications('e1'))
            .thenAnswer((_) async => Right([_n('a'), _n('b')]));
        return build();
      },
      act: (b) => b.add(const LoadNotificationsEvent('e1')),
      expect: () => [
        const EpisodeNotificationsLoading(),
        isA<EpisodeNotificationsLoaded>()
            .having((s) => s.notifications.length, 'count', 2),
      ],
    );

    blocTest<EpisodeNotificationsBloc, EpisodeNotificationsState>(
      'error',
      build: () {
        when(() => ds.listNotifications('e1'))
            .thenAnswer((_) async => const Left(GeneralFailure('boom')));
        return build();
      },
      act: (b) => b.add(const LoadNotificationsEvent('e1')),
      expect: () => [
        const EpisodeNotificationsLoading(),
        const EpisodeNotificationsError('boom'),
      ],
    );
  });

  group('create + delete', () {
    blocTest<EpisodeNotificationsBloc, EpisodeNotificationsState>(
      'create success appends',
      build: () {
        when(() => ds.createNotification('e1', any()))
            .thenAnswer((_) async => Right(_n('new')));
        return build();
      },
      seed: () => EpisodeNotificationsLoaded(notifications: [_n('a')]),
      act: (b) => b.add(const CreateNotificationEvent(
          episodeId: 'e1', body: {'channel': 'slack'})),
      expect: () => [
        isA<EpisodeNotificationsLoaded>()
            .having((s) => s.isMutating, 'mutating', true),
        isA<EpisodeNotificationsLoaded>()
            .having((s) => s.notifications.length, 'count', 2),
      ],
    );

    blocTest<EpisodeNotificationsBloc, EpisodeNotificationsState>(
      'delete optimistic + rollback',
      build: () {
        when(() => ds.deleteNotification('a'))
            .thenAnswer((_) async => const Left(GeneralFailure('fail')));
        return build();
      },
      seed: () => EpisodeNotificationsLoaded(notifications: [_n('a'), _n('b')]),
      act: (b) => b.add(const DeleteNotificationEvent('a')),
      expect: () => [
        isA<EpisodeNotificationsLoaded>()
            .having((s) => s.notifications.length, 'optimistic', 1),
        isA<EpisodeNotificationsLoaded>()
            .having((s) => s.notifications.length, 'restored', 2)
            .having((s) => s.lastActionError, 'error', 'fail'),
      ],
    );
  });

  group('send (Lock #7 / 503 path)', () {
    blocTest<EpisodeNotificationsBloc, EpisodeNotificationsState>(
      'success replaces row with sent',
      build: () {
        when(() => ds.sendNotification('a'))
            .thenAnswer((_) async => Right(_n('a', status: 'sent')));
        return build();
      },
      seed: () => EpisodeNotificationsLoaded(notifications: [_n('a')]),
      act: (b) => b.add(const SendNotificationEvent('a')),
      expect: () => [
        isA<EpisodeNotificationsLoaded>()
            .having((s) => s.isMutating, 'mutating', true),
        isA<EpisodeNotificationsLoaded>()
            .having((s) => s.notifications.first.status, 'sent', 'sent'),
      ],
    );

    blocTest<EpisodeNotificationsBloc, EpisodeNotificationsState>(
      '503: specific message "Notification provider not configured"',
      build: () {
        when(() => ds.sendNotification('a')).thenAnswer((_) async => const Left(
            HttpFailure(
                statusCode: 503,
                message: 'Notification sender is not configured')));
        return build();
      },
      seed: () => EpisodeNotificationsLoaded(notifications: [_n('a')]),
      act: (b) => b.add(const SendNotificationEvent('a')),
      expect: () => [
        isA<EpisodeNotificationsLoaded>()
            .having((s) => s.isMutating, 'mutating', true),
        isA<EpisodeNotificationsLoaded>()
            .having(
                (s) => s.notifications.first.status, 'still pending', 'pending')
            .having((s) => s.lastActionError, 'specific 503 message',
                'Notification provider not configured -- contact infra'),
      ],
    );

    blocTest<EpisodeNotificationsBloc, EpisodeNotificationsState>(
      'non-503 failure: server message preserved',
      build: () {
        when(() => ds.sendNotification('a')).thenAnswer((_) async => const Left(
            HttpFailure(statusCode: 500, message: 'provider error')));
        return build();
      },
      seed: () => EpisodeNotificationsLoaded(notifications: [_n('a')]),
      act: (b) => b.add(const SendNotificationEvent('a')),
      expect: () => [
        isA<EpisodeNotificationsLoaded>(),
        isA<EpisodeNotificationsLoaded>().having(
            (s) => s.lastActionError, 'server message', 'provider error'),
      ],
    );
  });

  blocTest<EpisodeNotificationsBloc, EpisodeNotificationsState>(
    'error acknowledged clears lastActionError',
    build: () => build(),
    seed: () => EpisodeNotificationsLoaded(
        notifications: [_n('a')], lastActionError: 'old'),
    act: (b) => b.add(const EpisodeNotificationsErrorAcknowledged()),
    expect: () => [
      isA<EpisodeNotificationsLoaded>()
          .having((s) => s.lastActionError, 'cleared', isNull),
    ],
  );
}
