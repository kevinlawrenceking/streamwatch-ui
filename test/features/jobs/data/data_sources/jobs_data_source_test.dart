import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/data/providers/rest_client.dart';
import 'package:streamwatch_frontend/data/sources/auth_data_source.dart';
import 'package:streamwatch_frontend/features/jobs/data/data_sources/jobs_data_source.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockRestClient extends Mock implements IRestClient {}

class MockAuthDataSource extends Mock implements IAuthDataSource {}

void main() {
  late MockRestClient client;
  late MockAuthDataSource auth;
  late JobsDataSource ds;

  setUp(() {
    client = MockRestClient();
    auth = MockAuthDataSource();
    ds = JobsDataSource(auth: auth, client: client);
    when(() => auth.getAuthToken()).thenAnswer((_) async => const Right('tok'));
  });

  String jobJson(String id, {String status = 'failed'}) => json.encode({
        'job_id': id,
        'status': status,
        'created_at': '2026-04-25T10:00:00Z',
      });

  test('list happy path returns parsed jobs', () async {
    when(() => client.get(
              endPoint: any(named: 'endPoint'),
              authToken: any(named: 'authToken'),
              queryParams: any(named: 'queryParams'),
            ))
        .thenAnswer((_) async =>
            http.Response('[${jobJson("j-1")},${jobJson("j-2")}]', 200));
    final result = await ds.listPodcastJobs();
    expect(result.isRight(), isTrue);
    result.forEach((list) => expect(list.length, 2));
  });

  test('list with filters passes status + podcast_id query params', () async {
    when(() => client.get(
          endPoint: any(named: 'endPoint'),
          authToken: any(named: 'authToken'),
          queryParams: any(named: 'queryParams'),
        )).thenAnswer((_) async => http.Response('[]', 200));
    await ds.listPodcastJobs(status: 'failed', podcastId: 'p-1');
    verify(() => client.get(
          endPoint: '/api/v1/podcast-jobs',
          authToken: 'tok',
          queryParams: {'status': 'failed', 'podcast_id': 'p-1'},
        )).called(1);
  });

  test('retry 202 returns Right(void)', () async {
    when(() => client.post(
          endPoint: any(named: 'endPoint'),
          authToken: any(named: 'authToken'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response('', 202));
    final result = await ds.retryPodcastJob('j-1');
    expect(result.isRight(), isTrue);
    verify(() => client.post(
          endPoint: '/api/v1/podcast-jobs/j-1/retry',
          authToken: 'tok',
          body: null,
        )).called(1);
  });

  test('retry 404 surfaces HttpFailure(statusCode: 404)', () async {
    when(() => client.post(
          endPoint: any(named: 'endPoint'),
          authToken: any(named: 'authToken'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response('{"error":"not found"}', 404));
    final result = await ds.retryPodcastJob('j-missing');
    expect(result.isLeft(), isTrue);
    result.swap().forEach((failure) {
      expect((failure as HttpFailure).statusCode, 404);
    });
  });
}
