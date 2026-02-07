import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:streamwatch_frontend/data/sources/auth_data_source.dart';
import 'package:streamwatch_frontend/features/login/bloc/login_bloc.dart';
import 'package:streamwatch_frontend/features/login/bloc/login_event.dart';
import 'package:streamwatch_frontend/features/login/bloc/login_state.dart';
import 'package:streamwatch_frontend/shared/bloc/auth_session_bloc.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockAuthDataSource extends Mock implements IAuthDataSource {}

class MockAuthSessionBloc extends Mock implements AuthSessionBloc {}

void main() {
  late MockAuthDataSource mockAuth;
  late MockAuthSessionBloc mockSessionBloc;

  setUp(() {
    mockAuth = MockAuthDataSource();
    mockSessionBloc = MockAuthSessionBloc();
    when(() => mockSessionBloc.add(any())).thenReturn(null);
  });

  setUpAll(() {
    registerFallbackValue(const LoginSuccessEvent());
    registerFallbackValue(const SessionRestoredEvent());
  });

  group('LoginBloc', () {
    test('initial state is LoginInitial', () {
      final bloc = LoginBloc(
        authDataSource: mockAuth,
        authSessionBloc: mockSessionBloc,
      );
      expect(bloc.state, isA<LoginInitial>());
      bloc.close();
    });

    blocTest<LoginBloc, LoginState>(
      'emits [LoginLoading, LoginSuccess] on successful login',
      build: () {
        when(() => mockAuth.authenticate(
              username: any(named: 'username'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => const Right('jwt-token'));
        return LoginBloc(
          authDataSource: mockAuth,
          authSessionBloc: mockSessionBloc,
        );
      },
      act: (bloc) => bloc.add(
        const LoginSubmitted(username: 'admin', password: 'secret'),
      ),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginSuccess>(),
      ],
      verify: (_) {
        verify(() => mockSessionBloc.add(any(that: isA<LoginSuccessEvent>())))
            .called(1);
      },
    );

    blocTest<LoginBloc, LoginState>(
      'emits [LoginLoading, LoginFailure] on failed login',
      build: () {
        when(() => mockAuth.authenticate(
              username: any(named: 'username'),
              password: any(named: 'password'),
            )).thenAnswer(
          (_) async => const Left(AuthFailure('invalid credentials')),
        );
        return LoginBloc(
          authDataSource: mockAuth,
          authSessionBloc: mockSessionBloc,
        );
      },
      act: (bloc) => bloc.add(
        const LoginSubmitted(username: 'admin', password: 'wrong'),
      ),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginFailure>(),
      ],
      verify: (_) {
        verifyNever(
            () => mockSessionBloc.add(any(that: isA<LoginSuccessEvent>())));
      },
    );

    blocTest<LoginBloc, LoginState>(
      'emits [LoginSuccess] when saved session exists',
      build: () {
        when(() => mockAuth.isAuthenticated())
            .thenAnswer((_) async => true);
        return LoginBloc(
          authDataSource: mockAuth,
          authSessionBloc: mockSessionBloc,
        );
      },
      act: (bloc) => bloc.add(const CheckSavedSession()),
      expect: () => [isA<LoginSuccess>()],
      verify: (_) {
        verify(() =>
                mockSessionBloc.add(any(that: isA<SessionRestoredEvent>())))
            .called(1);
      },
    );

    blocTest<LoginBloc, LoginState>(
      'stays at initial state when no saved session',
      build: () {
        when(() => mockAuth.isAuthenticated())
            .thenAnswer((_) async => false);
        return LoginBloc(
          authDataSource: mockAuth,
          authSessionBloc: mockSessionBloc,
        );
      },
      act: (bloc) => bloc.add(const CheckSavedSession()),
      expect: () => <LoginState>[],
    );
  });
}
