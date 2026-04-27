import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/data/providers/rest_client.dart';
import 'package:streamwatch_frontend/data/sources/auth_data_source.dart';
import 'package:streamwatch_frontend/features/watchlist/data/data_sources/guest_watchlist_data_source.dart';
import 'package:streamwatch_frontend/features/watchlist/data/models/change_status_request.dart';
import 'package:streamwatch_frontend/features/watchlist/data/models/patch_guest_watchlist_request.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockRestClient extends Mock implements IRestClient {}

class MockAuthDataSource extends Mock implements IAuthDataSource {}

void main() {
  late MockRestClient client;
  late MockAuthDataSource auth;
  late GuestWatchlistDataSource ds;

  setUp(() {
    client = MockRestClient();
    auth = MockAuthDataSource();
    ds = GuestWatchlistDataSource(auth: auth, client: client);
    when(() => auth.getAuthToken()).thenAnswer((_) async => const Right('tok'));
  });

  String entryJson(String id, {String status = 'active'}) => json.encode({
        'id': id,
        'guest_name': 'Guest $id',
        'aliases': const [],
        'priority': 'medium',
        'status': status,
        'created_at': '2026-04-25T10:00:00Z',
        'updated_at': '2026-04-25T10:00:00Z',
      });

  test('list happy path returns parsed entries', () async {
    when(() => client.get(
              endPoint: any(named: 'endPoint'),
              authToken: any(named: 'authToken'),
              queryParams: any(named: 'queryParams'),
            ))
        .thenAnswer((_) async =>
            http.Response('[${entryJson("a")},${entryJson("b")}]', 200));
    final result = await ds.listGuestWatchlistEntries(status: 'active');
    expect(result.isRight(), isTrue);
    result.forEach((list) => expect(list.length, 2));
  });

  test('create happy path POSTs and returns the created entry', () async {
    when(() => client.post(
          endPoint: any(named: 'endPoint'),
          authToken: any(named: 'authToken'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response(entryJson('new'), 201));
    final result =
        await ds.createGuestWatchlistEntry({'guest_name': 'Guest new'});
    expect(result.isRight(), isTrue);
    verify(() => client.post(
          endPoint: '/api/v1/podcast-guest-watchlist',
          authToken: 'tok',
          body: {'guest_name': 'Guest new'},
        )).called(1);
  });

  test('get happy path returns parsed entry', () async {
    when(() => client.get(
          endPoint: any(named: 'endPoint'),
          authToken: any(named: 'authToken'),
          queryParams: any(named: 'queryParams'),
        )).thenAnswer((_) async => http.Response(entryJson('x'), 200));
    final result = await ds.getGuestWatchlistEntry('x');
    expect(result.isRight(), isTrue);
  });

  test('patch happy path PATCHes and returns the updated entry', () async {
    when(() => client.patch(
          endPoint: any(named: 'endPoint'),
          authToken: any(named: 'authToken'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response(entryJson('x'), 200));
    final result = await ds.patchGuestWatchlistEntry(
      'x',
      const PatchGuestWatchlistEntryRequest(reason: 'updated reason'),
    );
    expect(result.isRight(), isTrue);
  });

  test('changeStatus happy path POSTs to /change-status', () async {
    when(() => client.post(
              endPoint: any(named: 'endPoint'),
              authToken: any(named: 'authToken'),
              body: any(named: 'body'),
            ))
        .thenAnswer(
            (_) async => http.Response(entryJson('x', status: 'matched'), 200));
    final result = await ds.changeGuestWatchlistEntryStatus(
      'x',
      const ChangeWatchlistStatusRequest(
        status: 'matched',
        matchedEpisodeId: 'ep-99',
      ),
    );
    expect(result.isRight(), isTrue);
    verify(() => client.post(
          endPoint: '/api/v1/podcast-guest-watchlist/x/change-status',
          authToken: 'tok',
          body: {'status': 'matched', 'matched_episode_id': 'ep-99'},
        )).called(1);
  });

  test('get 404 surfaces HttpFailure(statusCode: 404)', () async {
    when(() => client.get(
          endPoint: any(named: 'endPoint'),
          authToken: any(named: 'authToken'),
          queryParams: any(named: 'queryParams'),
        )).thenAnswer((_) async => http.Response('{"error":"not found"}', 404));
    final result = await ds.getGuestWatchlistEntry('missing');
    expect(result.isLeft(), isTrue);
    result.swap().forEach((failure) {
      expect(failure, isA<HttpFailure>());
      expect((failure as HttpFailure).statusCode, 404);
    });
  });

  test('patch 400 surfaces HttpFailure(statusCode: 400)', () async {
    when(() => client.patch(
              endPoint: any(named: 'endPoint'),
              authToken: any(named: 'authToken'),
              body: any(named: 'body'),
            ))
        .thenAnswer((_) async =>
            http.Response('{"error":"unknown field status"}', 400));
    final result = await ds.patchGuestWatchlistEntry(
      'x',
      const PatchGuestWatchlistEntryRequest(reason: 'r'),
    );
    expect(result.isLeft(), isTrue);
    result.swap().forEach((failure) {
      expect((failure as HttpFailure).statusCode, 400);
    });
  });

  test('changeStatus 409 surfaces HttpFailure(statusCode: 409)', () async {
    when(() => client.post(
              endPoint: any(named: 'endPoint'),
              authToken: any(named: 'authToken'),
              body: any(named: 'body'),
            ))
        .thenAnswer((_) async =>
            http.Response('{"error":"not found or not active"}', 409));
    final result = await ds.changeGuestWatchlistEntryStatus(
      'x',
      const ChangeWatchlistStatusRequest(status: 'expired'),
    );
    expect(result.isLeft(), isTrue);
    result.swap().forEach((failure) {
      expect((failure as HttpFailure).statusCode, 409);
    });
  });
}
