import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:streamwatch_frontend/data/providers/rest_client.dart';
import 'package:streamwatch_frontend/data/sources/auth_data_source.dart';
import 'package:streamwatch_frontend/data/sources/video_type_data_source.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockRestClient extends Mock implements IRestClient {}

class MockAuthDataSource extends Mock implements IAuthDataSource {}

void main() {
  late MockRestClient mockClient;
  late MockAuthDataSource mockAuth;
  late VideoTypeDataSource dataSource;

  setUp(() {
    mockClient = MockRestClient();
    mockAuth = MockAuthDataSource();
    dataSource = VideoTypeDataSource(auth: mockAuth, client: mockClient);

    when(() => mockAuth.getAuthToken())
        .thenAnswer((_) async => const Right('test-token'));
  });

  group('updateExemplar', () {
    test('returns Right(null) on 200 response', () async {
      when(() => mockClient.patch(
            endPoint: any(named: 'endPoint'),
            authToken: any(named: 'authToken'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            json.encode({'exemplar_id': 'ex-1', 'message': 'updated'}),
            HttpStatus.ok,
          ));

      final result = await dataSource.updateExemplar(
        'ex-1',
        weight: 2.5,
      );

      expect(result, const Right(null));
      verify(() => mockClient.patch(
            endPoint: '/api/v1/typecontrol/exemplars/ex-1',
            authToken: 'test-token',
            body: {'weight': 2.5},
          )).called(1);
    });

    test('returns Left(HttpFailure) on 404 response', () async {
      when(() => mockClient.patch(
            endPoint: any(named: 'endPoint'),
            authToken: any(named: 'authToken'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            json.encode({'error': 'Not found'}),
            HttpStatus.notFound,
          ));

      final result = await dataSource.updateExemplar(
        'ex-missing',
        weight: 2.5,
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<HttpFailure>());
          expect((failure as HttpFailure).statusCode, 404);
        },
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(HttpFailure) on 400 response', () async {
      when(() => mockClient.patch(
            endPoint: any(named: 'endPoint'),
            authToken: any(named: 'authToken'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            json.encode({'error': 'Bad request'}),
            HttpStatus.badRequest,
          ));

      final result = await dataSource.updateExemplar(
        'ex-1',
        weight: -1.0,
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<HttpFailure>());
          expect((failure as HttpFailure).statusCode, 400);
        },
        (_) => fail('Expected Left'),
      );
    });

    test('sparse body: weight only sends weight field', () async {
      when(() => mockClient.patch(
            endPoint: any(named: 'endPoint'),
            authToken: any(named: 'authToken'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            json.encode({'exemplar_id': 'ex-1', 'message': 'updated'}),
            HttpStatus.ok,
          ));

      await dataSource.updateExemplar('ex-1', weight: 2.5);

      verify(() => mockClient.patch(
            endPoint: '/api/v1/typecontrol/exemplars/ex-1',
            authToken: 'test-token',
            body: {'weight': 2.5},
          )).called(1);
    });

    test('sparse body: weight + notes sends both fields', () async {
      when(() => mockClient.patch(
            endPoint: any(named: 'endPoint'),
            authToken: any(named: 'authToken'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            json.encode({'exemplar_id': 'ex-1', 'message': 'updated'}),
            HttpStatus.ok,
          ));

      await dataSource.updateExemplar(
        'ex-1',
        weight: 2.5,
        notes: 'test',
      );

      verify(() => mockClient.patch(
            endPoint: '/api/v1/typecontrol/exemplars/ex-1',
            authToken: 'test-token',
            body: {'weight': 2.5, 'notes': 'test'},
          )).called(1);
    });

    test('sparse body: exemplarKind sends exemplar_kind field', () async {
      when(() => mockClient.patch(
            endPoint: any(named: 'endPoint'),
            authToken: any(named: 'authToken'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            json.encode({'exemplar_id': 'ex-1', 'message': 'updated'}),
            HttpStatus.ok,
          ));

      await dataSource.updateExemplar(
        'ex-1',
        exemplarKind: 'counter_example',
      );

      verify(() => mockClient.patch(
            endPoint: '/api/v1/typecontrol/exemplars/ex-1',
            authToken: 'test-token',
            body: {'exemplar_kind': 'counter_example'},
          )).called(1);
    });
  });
}
