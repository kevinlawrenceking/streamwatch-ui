import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/data/providers/rest_client.dart';
import 'package:streamwatch_frontend/data/sources/auth_data_source.dart';
import 'package:streamwatch_frontend/features/scheduler/reports/data/data_sources/reports_data_source.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockAuth extends Mock implements IAuthDataSource {}

class MockClient extends Mock implements IRestClient {}

void main() {
  late MockAuth auth;
  late MockClient client;
  late ReportsDataSource ds;

  setUp(() {
    auth = MockAuth();
    client = MockClient();
    ds = ReportsDataSource(auth: auth, client: client);
    when(() => auth.getAuthToken())
        .thenAnswer((_) async => const Right('tok'));
  });

  Map<String, dynamic> slotJson(String id) => {
        'id': id,
        'podcast_id': 'p1',
        'source': 'csv_import',
        'is_active': true,
        'created_at': '2026-04-20T12:00:00Z',
        'updated_at': '2026-04-20T12:00:00Z',
      };

  Map<String, dynamic> episodeJson(String id) => {
        'id': id,
        'podcast_id': 'p1',
        'title': 'Ep $id',
        'source': 'rss',
        'created_at': '2026-04-20T12:00:00Z',
      };

  http.Response ok200(Map<String, dynamic> envelope) =>
      http.Response(json.encode(envelope), 200);

  http.Response err(int status, [String msg = 'boom']) =>
      http.Response(json.encode({'error': msg}), status);

  group('expectedTodayScheduleSlots', () {
    test('200 happy path parses items + total', () async {
      when(() => client.get(
            endPoint: '/api/v1/reports/expected-today',
            authToken: any(named: 'authToken'),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => ok200({
            'items': [slotJson('s1'), slotJson('s2')],
            'page': 1,
            'page_size': 50,
            'total': 2,
            'total_pages': 1,
          }));

      final r = await ds.expectedTodayScheduleSlots();
      expect(r.isRight(), isTrue);
      r.fold((_) {}, (resp) {
        expect(resp.items.length, 2);
        expect(resp.total, 2);
        expect(resp.page, 1);
        expect(resp.pageSize, 50);
      });
    });

    test('200 with null items (Go nil-slice bug) treated as empty', () async {
      when(() => client.get(
            endPoint: '/api/v1/reports/expected-today',
            authToken: any(named: 'authToken'),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => ok200({
            'items': null,
            'page': 1,
            'page_size': 50,
            'total': 0,
            'total_pages': 1,
          }));

      final r = await ds.expectedTodayScheduleSlots();
      r.fold((_) => fail('expected Right'), (resp) {
        expect(resp.items, isEmpty);
        expect(resp.total, 0);
      });
    });

    test('500 maps to HttpFailure', () async {
      when(() => client.get(
            endPoint: '/api/v1/reports/expected-today',
            authToken: any(named: 'authToken'),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => err(500));

      final r = await ds.expectedTodayScheduleSlots();
      expect(r.isLeft(), isTrue);
      r.fold((f) => expect(f, isA<HttpFailure>()), (_) {});
    });
  });

  group('lateScheduleSlots', () {
    test('hits /api/v1/reports/late with page/pageSize forwarded', () async {
      when(() => client.get(
            endPoint: '/api/v1/reports/late',
            authToken: any(named: 'authToken'),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => ok200({
            'items': <dynamic>[],
            'page': 2,
            'page_size': 25,
            'total': 0,
            'total_pages': 1,
          }));

      final r = await ds.lateScheduleSlots(page: 2, pageSize: 25);
      expect(r.isRight(), isTrue);
      final captured = verify(() => client.get(
            endPoint: '/api/v1/reports/late',
            authToken: any(named: 'authToken'),
            queryParams: captureAny(named: 'queryParams'),
          )).captured.single as Map<String, String>;
      expect(captured['page'], '2');
      expect(captured['page_size'], '25');
    });
  });

  group('recentEpisodes', () {
    test('forwards optional hours param when provided', () async {
      when(() => client.get(
            endPoint: '/api/v1/reports/recent',
            authToken: any(named: 'authToken'),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => ok200({
            'items': [episodeJson('e1')],
            'page': 1,
            'page_size': 50,
            'total': 1,
            'total_pages': 1,
          }));

      await ds.recentEpisodes(hours: 48);
      final qp = verify(() => client.get(
            endPoint: '/api/v1/reports/recent',
            authToken: any(named: 'authToken'),
            queryParams: captureAny(named: 'queryParams'),
          )).captured.single as Map<String, String>;
      expect(qp['hours'], '48');
    });

    test('omits hours when null', () async {
      when(() => client.get(
            endPoint: '/api/v1/reports/recent',
            authToken: any(named: 'authToken'),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => ok200({
            'items': <dynamic>[],
            'page': 1,
            'page_size': 50,
            'total': 0,
            'total_pages': 1,
          }));

      await ds.recentEpisodes();
      final qp = verify(() => client.get(
            endPoint: '/api/v1/reports/recent',
            authToken: any(named: 'authToken'),
            queryParams: captureAny(named: 'queryParams'),
          )).captured.single as Map<String, String>;
      expect(qp.containsKey('hours'), isFalse);
    });
  });

  group('other episode reports hit correct slugs', () {
    for (final entry in <String, Future Function(ReportsDataSource)>{
      '/api/v1/reports/transcript-pending': (d) =>
          d.transcriptPendingEpisodes(),
      '/api/v1/reports/headline-ready': (d) => d.headlineReadyEpisodes(),
      '/api/v1/reports/pending-review': (d) => d.pendingReviewEpisodes(),
      '/api/v1/reports/pending-clip-request': (d) =>
          d.pendingClipRequestEpisodes(),
    }.entries) {
      test('calls ${entry.key}', () async {
        when(() => client.get(
              endPoint: entry.key,
              authToken: any(named: 'authToken'),
              queryParams: any(named: 'queryParams'),
            )).thenAnswer((_) async => ok200({
              'items': <dynamic>[],
              'page': 1,
              'page_size': 50,
              'total': 0,
              'total_pages': 1,
            }));
        final r = await entry.value(ds);
        expect(r.isRight(), isTrue);
      });
    }
  });

  group('markEpisodeReviewed', () {
    test('200 returns PodcastEpisodeModel', () async {
      when(() => client.post(
            endPoint: '/api/v1/podcast-episodes/e1/mark-reviewed',
            authToken: any(named: 'authToken'),
          )).thenAnswer((_) async => ok200({
            'id': 'e1',
            'podcast_id': 'p1',
            'title': 't',
            'created_at': '2026-04-20T12:00:00Z',
            'processing_status': 'reviewed',
          }));

      final r = await ds.markEpisodeReviewed('e1');
      r.fold((_) => fail('expected Right'), (e) {
        expect(e.id, 'e1');
        expect(e.processingStatus, 'reviewed');
      });
    });

    test('404 maps to HttpFailure(404)', () async {
      when(() => client.post(
            endPoint: '/api/v1/podcast-episodes/ex/mark-reviewed',
            authToken: any(named: 'authToken'),
          )).thenAnswer((_) async => err(404, 'Episode not found'));

      final r = await ds.markEpisodeReviewed('ex');
      r.fold((f) {
        expect(f, isA<HttpFailure>());
        expect((f as HttpFailure).statusCode, 404);
      }, (_) => fail('expected Left'));
    });

    test('409 maps to HttpFailure(409)', () async {
      when(() => client.post(
            endPoint: '/api/v1/podcast-episodes/ex/mark-reviewed',
            authToken: any(named: 'authToken'),
          )).thenAnswer((_) async => err(409,
              'backward transition not allowed: reviewed -> reviewed'));

      final r = await ds.markEpisodeReviewed('ex');
      r.fold((f) {
        expect((f as HttpFailure).statusCode, 409);
      }, (_) => fail('expected Left'));
    });
  });

  group('requestEpisodeClip', () {
    test('200 returns PodcastEpisodeModel with processing_status clip_requested',
        () async {
      when(() => client.post(
            endPoint: '/api/v1/podcast-episodes/e1/request-clip',
            authToken: any(named: 'authToken'),
          )).thenAnswer((_) async => ok200({
            'id': 'e1',
            'podcast_id': 'p1',
            'title': 't',
            'created_at': '2026-04-20T12:00:00Z',
            'processing_status': 'clip_requested',
          }));

      final r = await ds.requestEpisodeClip('e1');
      r.fold((_) => fail('expected Right'),
          (e) => expect(e.processingStatus, 'clip_requested'));
    });
  });
}
