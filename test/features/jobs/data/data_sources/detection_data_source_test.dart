import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/data/providers/rest_client.dart';
import 'package:streamwatch_frontend/data/sources/auth_data_source.dart';
import 'package:streamwatch_frontend/features/jobs/data/data_sources/detection_data_source.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockRestClient extends Mock implements IRestClient {}

class MockAuthDataSource extends Mock implements IAuthDataSource {}

void main() {
  late MockRestClient client;
  late MockAuthDataSource auth;
  late DetectionDataSource ds;

  setUp(() {
    client = MockRestClient();
    auth = MockAuthDataSource();
    ds = DetectionDataSource(auth: auth, client: client);
    when(() => auth.getAuthToken()).thenAnswer((_) async => const Right('tok'));
  });

  String runJson(String id, {String status = 'queued'}) => json.encode({
        'id': id,
        'episode_id': 'ep-1',
        'status': status,
        'created_at': '2026-04-25T10:00:00Z',
        'updated_at': '2026-04-25T10:00:00Z',
      });

  String actionJson(String id, int seq) => json.encode({
        'id': id,
        'run_id': 'r-1',
        'sequence_index': seq,
        'action_type': 'fetch',
        'created_at': '2026-04-25T10:00:00Z',
      });

  test('listDetectionRuns happy path returns parsed runs', () async {
    when(() => client.get(
          endPoint: any(named: 'endPoint'),
          authToken: any(named: 'authToken'),
          queryParams: any(named: 'queryParams'),
        )).thenAnswer((_) async => http.Response('[${runJson("r-1")}]', 200));
    final result = await ds.listDetectionRuns();
    expect(result.isRight(), isTrue);
    result.forEach((list) => expect(list.length, 1));
  });

  test('listDetectionRuns filters status + episode_id query params', () async {
    when(() => client.get(
          endPoint: any(named: 'endPoint'),
          authToken: any(named: 'authToken'),
          queryParams: any(named: 'queryParams'),
        )).thenAnswer((_) async => http.Response('[]', 200));
    await ds.listDetectionRuns(status: 'failed', episodeId: 'ep-1');
    verify(() => client.get(
          endPoint: '/api/v1/detection-runs',
          authToken: 'tok',
          queryParams: {'status': 'failed', 'episode_id': 'ep-1'},
        )).called(1);
  });

  test('getDetectionRun returns parsed single run', () async {
    when(() => client.get(
          endPoint: any(named: 'endPoint'),
          authToken: any(named: 'authToken'),
          queryParams: any(named: 'queryParams'),
        )).thenAnswer((_) async => http.Response(runJson('r-1'), 200));
    final result = await ds.getDetectionRun('r-1');
    expect(result.isRight(), isTrue);
  });

  test('listDetectionActions preserves server sequence_index order', () async {
    when(() => client.get(
          endPoint: any(named: 'endPoint'),
          authToken: any(named: 'authToken'),
          queryParams: any(named: 'queryParams'),
        )).thenAnswer((_) async => http.Response(
          '[${actionJson("a", 0)},${actionJson("b", 1)},${actionJson("c", 2)}]',
          200,
        ));
    final result = await ds.listDetectionActions('r-1');
    expect(result.isRight(), isTrue);
    result.forEach((list) {
      expect(list.map((a) => a.sequenceIndex).toList(), [0, 1, 2]);
    });
  });

  test('triggerDetection 202 returns parsed run', () async {
    when(() => client.post(
          endPoint: any(named: 'endPoint'),
          authToken: any(named: 'authToken'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response(runJson('r-new'), 202));
    final result = await ds.triggerDetection('ep-1');
    expect(result.isRight(), isTrue);
    verify(() => client.post(
          endPoint: '/api/v1/detections/trigger',
          authToken: 'tok',
          body: {'episode_id': 'ep-1'},
        )).called(1);
  });

  test('triggerDetection 409 surfaces HttpFailure(409)', () async {
    when(() => client.post(
              endPoint: any(named: 'endPoint'),
              authToken: any(named: 'authToken'),
              body: any(named: 'body'),
            ))
        .thenAnswer(
            (_) async => http.Response('{"error":"already active"}', 409));
    final result = await ds.triggerDetection('ep-1');
    expect(result.isLeft(), isTrue);
    result.swap().forEach((failure) {
      expect((failure as HttpFailure).statusCode, 409);
    });
  });

  test('triggerDetection 503 surfaces HttpFailure(503)', () async {
    when(() => client.post(
              endPoint: any(named: 'endPoint'),
              authToken: any(named: 'authToken'),
              body: any(named: 'body'),
            ))
        .thenAnswer(
            (_) async => http.Response('{"error":"SQS_UNCONFIGURED"}', 503));
    final result = await ds.triggerDetection('ep-1');
    expect(result.isLeft(), isTrue);
    result.swap().forEach((failure) {
      expect((failure as HttpFailure).statusCode, 503);
    });
  });

  test('batchTriggerDetection >50 items rejected client-side (no HTTP call)',
      () async {
    final tooMany = List.generate(51, (i) => 'ep-$i');
    final result = await ds.batchTriggerDetection(tooMany);
    expect(result.isLeft(), isTrue);
    result.swap().forEach((failure) {
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, 'Maximum 50 episodes per batch');
    });
    verifyNever(() => client.post(
          endPoint: any(named: 'endPoint'),
          authToken: any(named: 'authToken'),
          body: any(named: 'body'),
        ));
  });

  test('batchTriggerDetection 207 returns extracted per-item results',
      () async {
    final body = json.encode({
      'results': [
        {'episode_id': 'ep-1', 'status': 202, 'run_id': 'r-1'},
        {'episode_id': 'ep-2', 'status': 409, 'error_code': 'ALREADY_ACTIVE'},
        {
          'episode_id': 'ep-3',
          'status': 404,
          'error_code': 'EPISODE_NOT_FOUND',
        },
      ]
    });
    when(() => client.post(
          endPoint: any(named: 'endPoint'),
          authToken: any(named: 'authToken'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response(body, 207));
    final result = await ds.batchTriggerDetection(['ep-1', 'ep-2', 'ep-3']);
    expect(result.isRight(), isTrue);
    result.forEach((list) {
      expect(list.length, 3);
      expect(list[0].isSuccess, true);
      expect(list[1].isConflict, true);
      expect(list[2].isNotFound, true);
    });
  });

  test('batchTriggerDetection outer 503 surfaces HttpFailure(503)', () async {
    when(() => client.post(
              endPoint: any(named: 'endPoint'),
              authToken: any(named: 'authToken'),
              body: any(named: 'body'),
            ))
        .thenAnswer(
            (_) async => http.Response('{"error":"SQS_UNCONFIGURED"}', 503));
    final result = await ds.batchTriggerDetection(['ep-1', 'ep-2']);
    expect(result.isLeft(), isTrue);
    result.swap().forEach((failure) {
      expect((failure as HttpFailure).statusCode, 503);
    });
  });
}
