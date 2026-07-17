import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:neighbor_node/core/errors/failures.dart';
import 'package:neighbor_node/core/network/session_manager.dart';
import 'package:neighbor_node/features/auth/domain/entities/user_entity.dart';
import 'package:neighbor_node/features/auth/domain/repositories/auth_repository.dart';
import 'package:neighbor_node/features/auth/domain/usecases/get_current_user.dart';
import 'package:neighbor_node/features/auth/domain/usecases/login_user.dart';
import 'package:neighbor_node/features/auth/domain/usecases/logout.dart';
import 'package:neighbor_node/features/auth/domain/usecases/register_user.dart';
import 'package:neighbor_node/features/auth/presentation/bloc/auth_bloc.dart';

import 'auth_bloc_test.mocks.dart';

@GenerateNiceMocks([MockSpec<AuthRepository>()])
void main() {
  late MockAuthRepository repository;
  late SessionManager sessionManager;

  const testUser = UserEntity(
    id: 1,
    email: 'user@example.com',
    displayName: 'Test User',
    role: 'USER',
    rating: 0.0,
    isPhoneVerified: false,
  );

  setUp(() {
    repository = MockAuthRepository();
    sessionManager = SessionManager();
  });

  tearDown(() => sessionManager.dispose());

  AuthBloc buildBloc() => AuthBloc(
        login: LoginUser(repository),
        register: RegisterUser(repository),
        restoreSession: GetCurrentUser(repository),
        signOut: Logout(repository),
        sessionManager: sessionManager,
      );

  group('LoginSubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when login succeeds',
      build: () {
        when(repository.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => const Right(testUser));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const LoginSubmitted(email: 'user@example.com', password: 'pass1234'),
      ),
      expect: () => const [AuthLoading(), Authenticated(testUser)],
      verify: (_) {
        verify(repository.login(
          email: 'user@example.com',
          password: 'pass1234',
        )).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] with message when credentials are wrong',
      build: () {
        when(repository.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer(
          (_) async => const Left(AuthFailure('No active account found')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const LoginSubmitted(email: 'user@example.com', password: 'wrong'),
      ),
      expect: () => const [AuthLoading(), AuthError('No active account found')],
    );

    blocTest<AuthBloc, AuthState>(
      'surfaces DRF field errors through AuthError.fieldErrors',
      build: () {
        when(repository.register(
          email: anyNamed('email'),
          password: anyNamed('password'),
          displayName: anyNamed('displayName'),
        )).thenAnswer(
          (_) async => const Left(
            ValidationFailure(
              'A user with this email already exists.',
              {'email': ['A user with this email already exists.']},
            ),
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const RegisterSubmitted(
        email: 'dupe@example.com',
        password: 'pass1234',
        displayName: 'Dupe',
      )),
      expect: () => const [
        AuthLoading(),
        AuthError(
          'A user with this email already exists.',
          fieldErrors: {'email': ['A user with this email already exists.']},
        ),
      ],
    );
  });

  group('AppStarted', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when a session is restored',
      build: () {
        when(repository.getCurrentUser())
            .thenAnswer((_) async => const Right(testUser));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AppStarted()),
      expect: () => const [AuthLoading(), Authenticated(testUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when no session exists',
      build: () {
        when(repository.getCurrentUser())
            .thenAnswer((_) async => const Left(AuthFailure('Not signed in.')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AppStarted()),
      expect: () => const [AuthLoading(), Unauthenticated()],
    );
  });

  group('LogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Unauthenticated] and clears the session',
      build: () {
        when(repository.logout()).thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LogoutRequested()),
      expect: () => const [Unauthenticated()],
      verify: (_) => verify(repository.logout()).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'forced logout from SessionManager also emits Unauthenticated',
      build: () {
        when(repository.logout()).thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      act: (_) => sessionManager.notifyLoggedOut(),
      expect: () => const [Unauthenticated()],
    );
  });
}
