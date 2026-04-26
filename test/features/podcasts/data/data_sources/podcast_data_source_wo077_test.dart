import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/data/providers/rest_client.dart';
import 'package:streamwatch_frontend/data/sources/auth_data_source.dart';
import 'package:streamwatch_frontend/features/podcasts/data/data_sources/podcast_data_source.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockRestClient extends Mock implements IRestClient {}

class MockAuthDataSource extends Mock implements IAuthDataSource {}

void main() {
  late MockRestClient client;
  late MockAuthDataSource auth;
  late PodcastDataSource ds;

  setUp(() {
    client = MockRestClient();
    auth = MockAuthDataSource();
    ds = PodcastDataSource(auth: auth, client: client);
    when(() => auth.getAuthToken()).thenAnswer((_) async => const Right('tok'));
  });

  String _episodeJson(String id) => json.encode({
        'id': id,
        'podcast_id': 'p1',
        'title': 'Episode $id',
        'created_at': '2026-04-25T10:00:00Z',
      });

  String _transcriptJson(String id) => json.encode({
        'id': id,
        'episode_id': 'e1',
        'variant': 'raw',
        'source_type': 'auto',
        'created_at': '2026-04-25T10:00:00Z',
        'updated_at': '2026-04-25T10:00:00Z',
      });

  String _headlineJson(String id, {String status = 'pending'}) => json.encode({
        'id': id,
        'episode_id': 'e1',
        'status': status,
        'created_at': '2026-04-25T10:00:00Z',
        'updated_at': '2026-04-25T10:00:00Z',
      });

  String _notificationJson(String id, {String status = 'pending'}) =>
      json.encode({
        'id': id,
        'episode_id': 'e1',
        'channel': 'slack',
        'subject': 's',
        'body': 'b',
        'status': status,
        'created_at': '2026-04-25T10:00:00Z',
        'updated_at': '2026-04-25T10:00:00Z',
      });

  group('episode operations', () {
    test('updateEpisode hits PATCH /podcast-episodes/{id}', () async {
      when(() => client.patch(
            endPoint: any(named: 'endPoint'),
            authToken: any(named: 'authToken'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(_episodeJson('e1'), 200));

      final result = await ds.updateEpisode('e1', {'title': 'New'});
      expect(result.isRight(), isTrue);
      verify(() => client.patch(
            endPoint: '/api/v1/podcast-episodes/e1',
            authToken: 'tok',
            body: {'title': 'New'},
          )).called(1);
    });

    test('markEpisodeReviewed hits POST .../mark-reviewed', () async {
      when(() => client.post(
            endPoint: any(named: 'endPoint'),
            authToken: any(named: 'authToken'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(_episodeJson('e1'), 200));

      final result = await ds.markEpisodeReviewed('e1');
      expect(result.isRight(), isTrue);
      verify(() => client.post(
            endPoint: '/api/v1/podcast-episodes/e1/mark-reviewed',
            authToken: 'tok',
            body: null,
          )).called(1);
    });

    test('requestEpisodeClip 409 surfaces HttpFailure with statusCode',
        () async {
      when(() => client.post(
                endPoint: any(named: 'endPoint'),
                authToken: any(named: 'authToken'),
                body: any(named: 'body'),
              ))
          .thenAnswer((_) async => http.Response('{"error":"backward"}', 409));

      final result = await ds.requestEpisodeClip('e1');
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<HttpFailure>());
          expect((failure as HttpFailure).statusCode, 409);
        },
        (_) => fail('expected Left'),
      );
    });
  });

  group('transcripts', () {
    test('listTranscripts hits GET .../transcripts and parses array', () async {
      when(() => client.get(
                endPoint: any(named: 'endPoint'),
                authToken: any(named: 'authToken'),
                queryParams: any(named: 'queryParams'),
              ))
          .thenAnswer((_) async => http.Response(
              '[${_transcriptJson('a')},${_transcriptJson('b')}]', 200));

      final result = await ds.listTranscripts('e1');
      expect(result.isRight(), isTrue);
      result.fold((_) => fail('left'), (list) => expect(list.length, 2));
      verify(() => client.get(
            endPoint: '/api/v1/podcast-episodes/e1/transcripts',
            authToken: 'tok',
          )).called(1);
    });

    test('deleteTranscript accepts 204 No Content', () async {
      when(() => client.delete(
            endPoint: any(named: 'endPoint'),
            authToken: any(named: 'authToken'),
          )).thenAnswer((_) async => http.Response('', 204));

      final result = await ds.deleteTranscript('t1');
      expect(result.isRight(), isTrue);
      verify(() => client.delete(
            endPoint: '/api/v1/podcast-transcripts/t1',
            authToken: 'tok',
          )).called(1);
    });

    test('setPrimaryTranscript hits POST .../set-primary', () async {
      when(() => client.post(
            endPoint: any(named: 'endPoint'),
            authToken: any(named: 'authToken'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(_transcriptJson('t1'), 200));

      final result = await ds.setPrimaryTranscript('t1');
      expect(result.isRight(), isTrue);
      verify(() => client.post(
            endPoint: '/api/v1/podcast-transcripts/t1/set-primary',
            authToken: 'tok',
            body: null,
          )).called(1);
    });
  });

  group('headlines', () {
    test('generateHeadlines accepts 202 Accepted (not 200)', () async {
      when(() => client.post(
            endPoint: any(named: 'endPoint'),
            authToken: any(named: 'authToken'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('', HttpStatus.accepted));

      final result = await ds.generateHeadlines('e1');
      expect(result.isRight(), isTrue);
      verify(() => client.post(
            endPoint: '/api/v1/podcast-episodes/e1/generate-headlines',
            authToken: 'tok',
            body: null,
          )).called(1);
    });

    test('generateHeadlines rejects 200 (only 202 accepted)', () async {
      when(() => client.post(
            endPoint: any(named: 'endPoint'),
            authToken: any(named: 'authToken'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('{}', 200));

      final result = await ds.generateHeadlines('e1');
      expect(result.isLeft(), isTrue);
    });

    test('approveHeadlineCandidate 409 surfaces statusCode', () async {
      when(() => client.post(
                endPoint: any(named: 'endPoint'),
                authToken: any(named: 'authToken'),
                body: any(named: 'body'),
              ))
          .thenAnswer(
              (_) async => http.Response('{"error":"not pending"}', 409));

      final result = await ds.approveHeadlineCandidate('h1');
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect((f as HttpFailure).statusCode, 409),
        (_) => fail('expected Left'),
      );
    });

    test('listHeadlineCandidates parses array', () async {
      when(() => client.get(
                endPoint: any(named: 'endPoint'),
                authToken: any(named: 'authToken'),
                queryParams: any(named: 'queryParams'),
              ))
          .thenAnswer(
              (_) async => http.Response('[${_headlineJson('a')}]', 200));

      final result = await ds.listHeadlineCandidates('e1');
      expect(result.isRight(), isTrue);
      result.fold((_) => fail('left'), (list) => expect(list.length, 1));
    });
  });

  group('notifications', () {
    test('sendNotification 503 surfaces statusCode', () async {
      when(() => client.post(
                endPoint: any(named: 'endPoint'),
                authToken: any(named: 'authToken'),
                body: any(named: 'body'),
              ))
          .thenAnswer((_) async =>
              http.Response('{"error":"sender not configured"}', 503));

      final result = await ds.sendNotification('n1');
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect((f as HttpFailure).statusCode, 503),
        (_) => fail('expected Left'),
      );
    });

    test('sendNotification success returns updated row', () async {
      when(() => client.post(
                endPoint: any(named: 'endPoint'),
                authToken: any(named: 'authToken'),
                body: any(named: 'body'),
              ))
          .thenAnswer((_) async =>
              http.Response(_notificationJson('n1', status: 'sent'), 200));

      final result = await ds.sendNotification('n1');
      expect(result.isRight(), isTrue);
      verify(() => client.post(
            endPoint: '/api/v1/podcast-notifications/n1/send',
            authToken: 'tok',
            body: null,
          )).called(1);
    });

    test('createNotification accepts 201 Created', () async {
      when(() => client.post(
                endPoint: any(named: 'endPoint'),
                authToken: any(named: 'authToken'),
                body: any(named: 'body'),
              ))
          .thenAnswer((_) async => http.Response(_notificationJson('n1'), 201));

      final result = await ds.createNotification('e1', {'channel': 'slack'});
      expect(result.isRight(), isTrue);
    });

    test('listNotifications empty body returns empty list', () async {
      when(() => client.get(
            endPoint: any(named: 'endPoint'),
            authToken: any(named: 'authToken'),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => http.Response('', 200));

      final result = await ds.listNotifications('e1');
      expect(result.isRight(), isTrue);
      result.fold((_) => fail('left'), (list) => expect(list, isEmpty));
    });
  });
}
