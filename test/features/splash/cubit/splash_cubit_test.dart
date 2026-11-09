import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawalo_mobile/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  const user = UserEntity(
    id: 'u1',
    email: 'u1@k.com',
    name: 'User 1',
    groups: [],
  );

  late MockSecureStorageService storage;
  late MockAuthBloc authBloc;

  setUpAll(() => registerFallbackValue(const AuthCheckRequested()));

  setUp(() {
    storage = MockSecureStorageService();
    authBloc = MockAuthBloc();
    when(storage.isOnboardingCompleted).thenAnswer((_) async => true);
    when(storage.getAccessToken).thenAnswer((_) async => null);
  });

  SplashCubit build({
    AuthBloc? bloc,
    Duration timeout = const Duration(seconds: 5),
    Future<void> Function()? onInitialize,
  }) => SplashCubit(
    storage: storage,
    authBloc: bloc,
    authTimeout: timeout,
    onInitialize: onInitialize,
  );

  test('already authenticated bloc skips the auth check', () async {
    when(() => authBloc.state).thenReturn(const Authenticated(user: user));
    final cubit = build(bloc: authBloc);

    await cubit.initialize();

    expect(cubit.state.isReady, isTrue);
    expect(cubit.state.isOnboardingCompleted, isTrue);
    expect(cubit.state.isAuthenticated, isTrue);
    expect(cubit.state.user, user);
    verifyNever(() => authBloc.add(any()));
    await cubit.close();
  });

  test('group selection state is surfaced with its user', () async {
    when(
      () => authBloc.state,
    ).thenReturn(const GroupSelectionRequired(user: user));
    final cubit = build(bloc: authBloc);

    await cubit.initialize();

    expect(cubit.state.isGroupSelectionRequired, isTrue);
    expect(cubit.state.isAuthenticated, isFalse);
    expect(cubit.state.user, user);
    await cubit.close();
  });

  test('requests an auth check and waits for the settled state', () async {
    when(() => authBloc.state).thenReturn(const AuthInitial());
    when(() => authBloc.stream).thenAnswer(
      (_) => Stream.fromIterable([
        const AuthLoading(),
        const Authenticated(user: user),
      ]),
    );
    final cubit = build(bloc: authBloc);

    await cubit.initialize();

    verify(() => authBloc.add(const AuthCheckRequested())).called(1);
    expect(cubit.state.isAuthenticated, isTrue);
    await cubit.close();
  });

  test('times out waiting for the bloc and uses its current state', () async {
    when(() => authBloc.state).thenReturn(const AuthInitial());
    when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
    final cubit = build(
      bloc: authBloc,
      timeout: const Duration(milliseconds: 10),
    );

    await cubit.initialize();

    expect(cubit.state.isReady, isTrue);
    expect(cubit.state.isAuthenticated, isFalse);
    await cubit.close();
  });

  test('without an AuthBloc the stored token decides', () async {
    when(storage.getAccessToken).thenAnswer((_) async => 'token');
    final cubit = build();

    await cubit.initialize();

    expect(cubit.state.isAuthenticated, isTrue);
    await cubit.close();
  });

  test('empty token means unauthenticated', () async {
    when(storage.getAccessToken).thenAnswer((_) async => '');
    final cubit = build();

    await cubit.initialize();

    expect(cubit.state.isAuthenticated, isFalse);
    await cubit.close();
  });

  test('storage failures degrade to defaults and still finish', () async {
    when(storage.isOnboardingCompleted).thenThrow(StateError('boom'));
    when(storage.getAccessToken).thenThrow(StateError('boom'));
    final cubit = build();

    await cubit.initialize();

    expect(cubit.state.isReady, isTrue);
    expect(cubit.state.isOnboardingCompleted, isFalse);
    expect(cubit.state.isAuthenticated, isFalse);
    await cubit.close();
  });

  test('onInitialize failure still marks the splash ready', () async {
    final cubit = build(onInitialize: () async => throw StateError('boom'));

    await expectLater(cubit.initialize(), throwsStateError);

    expect(cubit.state.isReady, isTrue);
    expect(cubit.state.isOnboardingCompleted, isFalse);
    await cubit.close();
  });
}
