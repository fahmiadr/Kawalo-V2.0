import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart' hide AuthFailure;
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/switch_group_usecase.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mocktail/mocktail.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockSwitchGroupUseCase extends Mock implements SwitchGroupUseCase {}

void main() {
  late AuthBloc authBloc;
  late MockLoginUseCase mockLoginUseCase;
  late MockAuthRepository mockAuthRepository;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockSwitchGroupUseCase mockSwitchGroupUseCase;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockAuthRepository = MockAuthRepository();
    when(
      () => mockAuthRepository.getActiveSession(),
    ).thenAnswer((_) async => const Right<Failure, AuthSessionEntity?>(null));
    mockLogoutUseCase = MockLogoutUseCase();
    mockSwitchGroupUseCase = MockSwitchGroupUseCase();
    authBloc = AuthBloc(
      loginUseCase: mockLoginUseCase,
      switchGroupUseCase: mockSwitchGroupUseCase,
      authRepository: mockAuthRepository,
      logoutUseCase: mockLogoutUseCase,
    );
    registerFallbackValue(const LoginParams(email: '', password: ''));
    registerFallbackValue(const SwitchGroupParams(groupUid: ''));
    registerFallbackValue(const NoParams());
  });

  tearDown(() {
    authBloc.close();
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tUserEntity = UserEntity(
    id: 'user_1',
    email: tEmail,
    name: 'Test User',
    groups: [],
  );

  test('initial state should be AuthInitial', () {
    expect(authBloc.state, equals(const AuthInitial()));
  });

  group('LoginSubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when LoginSubmitted succeeds',
      build: () {
        when(
          () => mockLoginUseCase(any()),
        ).thenAnswer((_) async => const Right(tUserEntity));
        return authBloc;
      },
      act: (bloc) =>
          bloc.add(const LoginSubmitted(email: tEmail, password: tPassword)),
      expect: () => [
        const AuthLoading(),
        const Authenticated(user: tUserEntity),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when LoginSubmitted fails',
      build: () {
        when(
          () => mockLoginUseCase(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Invalid Login')));
        return authBloc;
      },
      act: (bloc) =>
          bloc.add(const LoginSubmitted(email: tEmail, password: tPassword)),
      expect: () => [
        const AuthLoading(),
        const AuthFailure(message: 'Invalid Login'),
      ],
    );
    const tMultiGroupUser = UserEntity(
      id: 'user_1',
      email: tEmail,
      name: 'Test User',
      groups: [
        UserGroupEntity(
          groupUid: 'GRP-1',
          groupName: 'Group 1',
          allowAdmin: false,
          allowPatrol: false,
          allowMonPatrol: false,
          features: [],
        ),
        UserGroupEntity(
          groupUid: 'GRP-2',
          groupName: 'Group 2',
          allowAdmin: false,
          allowPatrol: false,
          allowMonPatrol: false,
          features: [],
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, GroupSelectionRequired] '
      'when LoginSubmitted succeeds with multiple groups',
      build: () {
        when(
          () => mockLoginUseCase(any()),
        ).thenAnswer((_) async => const Right(tMultiGroupUser));
        return authBloc;
      },
      act: (bloc) =>
          bloc.add(const LoginSubmitted(email: tEmail, password: tPassword)),
      expect: () => [
        const AuthLoading(),
        const GroupSelectionRequired(user: tMultiGroupUser),
      ],
    );
  });

  group('SwitchGroupSubmitted', () {
    const tSwitchedUser = UserEntity(
      id: 'user_1',
      email: tEmail,
      name: 'Test User',
      groups: [],
      activeGroup: UserGroupEntity(
        groupUid: 'GRP-2',
        groupName: 'Group 2',
        allowAdmin: false,
        allowPatrol: false,
        allowMonPatrol: false,
        features: [],
      ),
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when SwitchGroupSubmitted succeeds',
      build: () {
        when(
          () => mockSwitchGroupUseCase(any()),
        ).thenAnswer((_) async => const Right(tSwitchedUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(const SwitchGroupSubmitted(groupUid: 'GRP-2')),
      expect: () => [
        const AuthLoading(),
        const Authenticated(user: tSwitchedUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when SwitchGroupSubmitted fails',
      build: () {
        when(() => mockSwitchGroupUseCase(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Gagal beralih grup')),
        );
        return authBloc;
      },
      act: (bloc) => bloc.add(const SwitchGroupSubmitted(groupUid: 'GRP-2')),
      expect: () => [
        const AuthLoading(),
        const AuthFailure(message: 'Gagal beralih grup'),
      ],
    );
  });

  group('LogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when LogoutRequested succeeds',
      build: () {
        when(
          () => mockLogoutUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(const LogoutRequested()),
      expect: () => [const AuthLoading(), const Unauthenticated()],
    );
  });

  group('LogoutRequested with message', () {
    blocTest<AuthBloc, AuthState>(
      'carries the message into Unauthenticated for the login screen',
      build: () {
        when(
          () => mockLogoutUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(const LogoutRequested(message: 'Silakan masuk.')),
      expect: () => [
        const AuthLoading(),
        const Unauthenticated(message: 'Silakan masuk.'),
      ],
    );
  });

  group('AvatarUpdated', () {
    blocTest<AuthBloc, AuthState>(
      'replaces the photo of the authenticated user and keeps the session',
      build: () => authBloc,
      seed: () => const Authenticated(user: tUserEntity),
      act: (bloc) => bloc.add(const AvatarUpdated('https://x/a.webp')),
      expect: () => [
        Authenticated(user: tUserEntity.withAvatar('https://x/a.webp')),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'null removes the photo',
      build: () => authBloc,
      seed: () => Authenticated(user: tUserEntity.withAvatar('https://x/a')),
      act: (bloc) => bloc.add(const AvatarUpdated(null)),
      expect: () => [const Authenticated(user: tUserEntity)],
    );

    blocTest<AuthBloc, AuthState>(
      'is ignored when nobody is authenticated',
      build: () => authBloc,
      act: (bloc) => bloc.add(const AvatarUpdated('https://x/a.webp')),
      expect: () => <AuthState>[],
    );
  });

  group('AuthCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when active session is found',
      build: () {
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenAnswer((_) async => const Right(tUserEntity));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [
        const AuthLoading(),
        const Authenticated(user: tUserEntity),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when no session is found',
      build: () {
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [const AuthLoading(), const Unauthenticated()],
    );

    const tMultiGroupUser = UserEntity(
      id: 'user_multi',
      email: 'multi@example.com',
      name: 'Multi User',
      groups: [
        UserGroupEntity(
          groupUid: 'g1',
          groupName: 'Group 1',
          allowAdmin: false,
          allowPatrol: false,
          allowMonPatrol: false,
          features: [],
        ),
        UserGroupEntity(
          groupUid: 'g2',
          groupName: 'Group 2',
          allowAdmin: false,
          allowPatrol: false,
          allowMonPatrol: false,
          features: [],
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, GroupSelectionRequired] when user has multiple '
      'groups but no active group',
      build: () {
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenAnswer((_) async => const Right(tMultiGroupUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [
        const AuthLoading(),
        const GroupSelectionRequired(user: tMultiGroupUser),
      ],
    );
  });
}
