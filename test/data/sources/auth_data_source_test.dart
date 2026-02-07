import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:streamwatch_frontend/data/providers/rest_client.dart';
import 'package:streamwatch_frontend/data/sources/auth_data_source.dart';
import 'package:streamwatch_frontend/shared/bloc/auth_session_bloc.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockRestClient extends Mock implements IRestClient {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockAuthSessionBloc extends Mock implements AuthSessionBloc {}

/// Creates a valid JWT token with the given expiry timestamp.
String _makeJwt({required int exp}) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final payload = base64Url.encode(utf8.encode('{"exp":$exp,"sub":"user1"}'));
  const signature = 'test-signature';
  return '$header.$payload.$signature';
}

void main() {
  late MockRestClient mockClient;
  late MockFlutterSecureStorage mockStorage;
  late MockAuthSessionBloc mockAuthBloc;
  late ProdAuthDataSource dataSource;

  setUp(() {
    mockClient = MockRestClient();
    mockStorage = MockFlutterSecureStorage();
    mockAuthBloc = MockAuthSessionBloc();

    // Stub void methods
    when(() => mockAuthBloc.add(any())).thenReturn(null);

    dataSource = ProdAuthDataSource(
      client: mockClient,
      authSessionBloc: mockAuthBloc,
      storage: mockStorage,
    );
  });

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
    registerFallbackValue(const SessionExpiredEvent());
  });

  group('authenticate', () {
    test('returns token on success', () async {
      final token = _makeJwt(
        exp: DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      );

      when(() => mockClient.post(
            endPoint: '/api/v1/auth',
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            json.encode({'token': token}),
            200,
          ));
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      final result = await dataSource.authenticate(
        username: 'admin',
        password: 'secret',
      );

      expect(result, isA<Right<Failure, String>>());
      result.fold(
        (_) => fail('Expected Right'),
        (t) => expect(t, token),
      );

      verify(() => mockClient.post(
            endPoint: '/api/v1/auth',
            headers: {'x-username': 'admin', 'x-password': 'secret'},
          )).called(1);
      verify(() => mockStorage.write(
            key: 'streamwatch_auth_token',
            value: token,
          )).called(1);
    });

    test('returns AuthFailure on 401', () async {
      when(() => mockClient.post(
            endPoint: '/api/v1/auth',
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            json.encode({'code': 'ERR_AUTH', 'message': 'invalid credentials'}),
            401,
          ));

      final result = await dataSource.authenticate(
        username: 'admin',
        password: 'wrong',
      );

      expect(result, isA<Left<Failure, String>>());
      result.fold(
        (f) => expect(f, isA<AuthFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns NetworkFailure on exception', () async {
      when(() => mockClient.post(
            endPoint: '/api/v1/auth',
            headers: any(named: 'headers'),
          )).thenThrow(Exception('network error'));

      final result = await dataSource.authenticate(
        username: 'admin',
        password: 'secret',
      );

      expect(result, isA<Left<Failure, String>>());
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('getAuthToken', () {
    test('returns cached token if valid', () async {
      // First authenticate to cache a token
      final token = _makeJwt(
        exp: DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      );

      when(() => mockClient.post(
            endPoint: '/api/v1/auth',
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            json.encode({'token': token}),
            200,
          ));
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      await dataSource.authenticate(username: 'admin', password: 'secret');

      final result = await dataSource.getAuthToken();

      expect(result, isA<Right<Failure, String>>());
      result.fold(
        (_) => fail('Expected Right'),
        (t) => expect(t, token),
      );
    });

    test('reads from storage when no cached token', () async {
      final token = _makeJwt(
        exp: DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      );

      when(() => mockStorage.read(key: 'streamwatch_auth_token'))
          .thenAnswer((_) async => token);

      final result = await dataSource.getAuthToken();

      expect(result, isA<Right<Failure, String>>());
      result.fold(
        (_) => fail('Expected Right'),
        (t) => expect(t, token),
      );
    });

    test('attempts refresh when token expired, succeeds', () async {
      final expiredToken = _makeJwt(
        exp: DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      );
      final newToken = _makeJwt(
        exp: DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      );

      when(() => mockStorage.read(key: 'streamwatch_auth_token'))
          .thenAnswer((_) async => expiredToken);
      when(() => mockClient.get(
            endPoint: '/api/v1/token',
            authToken: expiredToken,
          )).thenAnswer((_) async => http.Response(
            json.encode({'token': newToken}),
            200,
          ));
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      final result = await dataSource.getAuthToken();

      expect(result, isA<Right<Failure, String>>());
      result.fold(
        (_) => fail('Expected Right'),
        (t) => expect(t, newToken),
      );
    });

    test('returns SessionExpiredFailure when refresh fails', () async {
      final expiredToken = _makeJwt(
        exp: DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      );

      when(() => mockStorage.read(key: 'streamwatch_auth_token'))
          .thenAnswer((_) async => expiredToken);
      when(() => mockClient.get(
            endPoint: '/api/v1/token',
            authToken: expiredToken,
          )).thenAnswer((_) async => http.Response('', 401));
      when(() => mockStorage.delete(key: 'streamwatch_auth_token'))
          .thenAnswer((_) async {});

      final result = await dataSource.getAuthToken();

      expect(result, isA<Left<Failure, String>>());
      result.fold(
        (f) => expect(f, isA<SessionExpiredFailure>()),
        (_) => fail('Expected Left'),
      );

      verify(() => mockAuthBloc.add(any(that: isA<SessionExpiredEvent>()))).called(1);
    });

    test('returns SessionExpiredFailure when no stored token', () async {
      when(() => mockStorage.read(key: 'streamwatch_auth_token'))
          .thenAnswer((_) async => null);
      when(() => mockStorage.delete(key: 'streamwatch_auth_token'))
          .thenAnswer((_) async {});

      final result = await dataSource.getAuthToken();

      expect(result, isA<Left<Failure, String>>());
    });
  });

  group('logout', () {
    test('clears storage and cache', () async {
      when(() => mockStorage.delete(key: 'streamwatch_auth_token'))
          .thenAnswer((_) async {});

      final result = await dataSource.logout();

      expect(result, isA<Right<Failure, void>>());
      verify(() => mockStorage.delete(key: 'streamwatch_auth_token')).called(1);
    });
  });

  group('isAuthenticated', () {
    test('returns true when valid token exists', () async {
      final token = _makeJwt(
        exp: DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      );

      when(() => mockStorage.read(key: 'streamwatch_auth_token'))
          .thenAnswer((_) async => token);

      final result = await dataSource.isAuthenticated();

      expect(result, isTrue);
    });

    test('returns false when no token', () async {
      when(() => mockStorage.read(key: 'streamwatch_auth_token'))
          .thenAnswer((_) async => null);
      when(() => mockStorage.delete(key: 'streamwatch_auth_token'))
          .thenAnswer((_) async {});

      final result = await dataSource.isAuthenticated();

      expect(result, isFalse);
    });
  });

  group('JWT parsing edge cases', () {
    test('treats malformed JWT as expired', () async {
      when(() => mockStorage.read(key: 'streamwatch_auth_token'))
          .thenAnswer((_) async => 'not.a.valid.jwt');
      when(() => mockStorage.delete(key: 'streamwatch_auth_token'))
          .thenAnswer((_) async {});

      final result = await dataSource.isAuthenticated();

      expect(result, isFalse);
    });

    test('treats JWT without exp claim as expired', () async {
      final header = base64Url.encode(utf8.encode('{"alg":"HS256"}'));
      final payload = base64Url.encode(utf8.encode('{"sub":"user1"}'));
      final token = '$header.$payload.sig';

      when(() => mockStorage.read(key: 'streamwatch_auth_token'))
          .thenAnswer((_) async => token);
      when(() => mockStorage.delete(key: 'streamwatch_auth_token'))
          .thenAnswer((_) async {});

      final result = await dataSource.isAuthenticated();

      expect(result, isFalse);
    });
  });
}
