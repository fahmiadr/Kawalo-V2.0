import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/screens/main_navigation_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_screen_cubits.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

final Finder masukButton = find.widgetWithText(AppTaskButton, 'Masuk');

void main() {
  setUpAll(() {
    registerFallbackValue(const LoginParams(email: '', password: ''));
  });

  Widget createWidgetUnderTest(MockLoginUseCase mockLoginUseCase) {
    return BlocProvider<InformationCubit>.value(
      value: createStubbedInformationCubit(),
      child: M3EMaterialApp(
        data: AppTheme.m3eLight(),
        home: BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(loginUseCase: mockLoginUseCase),
          child: const LoginScreen(),
        ),
      ),
    );
  }

  testWidgets(
    'LoginScreen renders header, form inputs, consent links, and CTA button',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockLoginUseCase = MockLoginUseCase();

      await tester.pumpWidget(createWidgetUnderTest(mockLoginUseCase));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        find.text('Pakai akun Kawalo dari admin grup Anda.'),
        findsOneWidget,
      );
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(masukButton, findsOneWidget);
      expect(find.text('Lupa password?'), findsOneWidget);
    },
  );

  testWidgets('shows warning when empty fields are submitted', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockLoginUseCase = MockLoginUseCase();

    await tester.pumpWidget(createWidgetUnderTest(mockLoginUseCase));
    await tester.pumpAndSettle();

    await tester.tap(masukButton);
    await tester.pumpAndSettle();

    expect(find.text('Harap isi email terlebih dahulu.'), findsOneWidget);
    expect(find.text('Harap isi password terlebih dahulu.'), findsOneWidget);
    verifyNever(() => mockLoginUseCase(any()));
  });

  testWidgets('auto-focuses email field when both fields are empty on submit', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockLoginUseCase = MockLoginUseCase();

    await tester.pumpWidget(createWidgetUnderTest(mockLoginUseCase));
    await tester.pumpAndSettle();

    await tester.tap(masukButton);
    await tester.pumpAndSettle();

    // M3: first invalid field (email) must receive focus automatically.
    final emailField = tester.widget<AppTextField>(
      find.byType(AppTextField).first,
    );
    expect(emailField.focusNode?.hasFocus, isTrue);
    verifyNever(() => mockLoginUseCase(any()));
  });

  testWidgets('fields are disabled (busy state) while AuthLoading is active', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Use a Completer so the mock hangs with no pending timer.
    // fake_async throws if a real Duration timer outlives the widget tree.
    final completer = Completer<Either<Failure, UserEntity>>();
    final mockLoginUseCase = MockLoginUseCase();
    when(() => mockLoginUseCase(any())).thenAnswer((_) => completer.future);

    await tester.pumpWidget(createWidgetUnderTest(mockLoginUseCase));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(EditableText).first,
      'admin@kawalo.co.id',
    );
    await tester.enterText(find.byType(EditableText).last, 'password123');
    await tester.pumpAndSettle();

    await tester.tap(masukButton);
    // One pump so the BLoC emits AuthLoading before the future resolves.
    await tester.pump();

    // M3 Busy State: both AppTextFields must be disabled while loading.
    final textFields = tester.widgetList<AppTextField>(
      find.byType(AppTextField),
    );
    for (final field in textFields) {
      expect(
        field.enabled,
        isFalse,
        reason: 'Field harus disabled saat AuthLoading aktif',
      );
    }

    final button = tester.widget<AppTaskButton>(
      find.widgetWithText(AppTaskButton, 'Memeriksa…'),
    );
    expect(button.isLoading, isTrue);
    expect(find.text('Memeriksa…'), findsOneWidget);

    // Release the completer so the BLoC and widget tree can settle cleanly.
    completer.complete(
      const Right(
        UserEntity(id: 'u1', email: 'a@b.co', name: 'Test', groups: []),
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets(
    'submits LoginSubmitted when valid credentials are typed and Masuk is '
    'tapped',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockLoginUseCase = MockLoginUseCase();
      when(() => mockLoginUseCase(any())).thenAnswer(
        (_) async => const Right(
          UserEntity(
            id: 'u1',
            email: 'admin@kawalo.co.id',
            name: 'Super Admin',
            groups: [],
          ),
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest(mockLoginUseCase));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(EditableText).first,
        'admin@kawalo.co.id',
      );
      await tester.enterText(find.byType(EditableText).last, 'password123');
      await tester.pumpAndSettle();

      await tester.tap(masukButton);
      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => mockLoginUseCase(any())).called(1);
      expect(find.byType(MainNavigationScreen), findsOneWidget);
    },
  );

  testWidgets('displays sessionExpiredMessage in snackbar when provided', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockLoginUseCase = MockLoginUseCase();

    await tester.pumpWidget(
      M3EMaterialApp(
        data: AppTheme.m3eLight(),
        home: BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(loginUseCase: mockLoginUseCase),
          child: const LoginScreen(
            sessionExpiredMessage:
                'Sesi Anda telah berakhir demi keamanan. '
                'Silakan masuk kembali.',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Sesi Anda telah berakhir demi keamanan. '
        'Silakan masuk kembali.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('keeps the Masuk button visible above the keyboard', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    final mockLoginUseCase = MockLoginUseCase();

    await tester.pumpWidget(createWidgetUnderTest(mockLoginUseCase));
    await tester.pumpAndSettle();

    final masukButtonFinder = masukButton;
    expect(masukButtonFinder, findsOneWidget);

    // Simulate keyboard appearing and tap email field
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.tap(find.byType(EditableText).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(masukButtonFinder, findsOneWidget);
  });

  testWidgets('pre-fills the email saved by the previous login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final storage = MockSecureStorageService();
    when(storage.getLastEmail).thenAnswer((_) async => 'saved@kawalo.id');

    await tester.pumpWidget(
      RepositoryProvider<SecureStorageService>.value(
        value: storage,
        child: M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(loginUseCase: MockLoginUseCase()),
            child: const LoginScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('saved@kawalo.id'), findsOneWidget);
  });

  testWidgets('does not overwrite an email the user already typed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final storage = MockSecureStorageService();
    final saved = Completer<String?>();
    when(storage.getLastEmail).thenAnswer((_) => saved.future);

    await tester.pumpWidget(
      RepositoryProvider<SecureStorageService>.value(
        value: storage,
        child: M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(loginUseCase: MockLoginUseCase()),
            child: const LoginScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, 'typed@kawalo.id');
    saved.complete('saved@kawalo.id');
    await tester.pumpAndSettle();

    expect(find.text('typed@kawalo.id'), findsOneWidget);
    expect(find.text('saved@kawalo.id'), findsNothing);
  });

  group('failures', () {
    Future<void> submitWith(WidgetTester tester, Failure failure) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final mockLoginUseCase = MockLoginUseCase();
      when(
        () => mockLoginUseCase(any()),
      ).thenAnswer((_) async => Left(failure));
      await tester.pumpWidget(createWidgetUnderTest(mockLoginUseCase));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).first, 'a@kawalo.id');
      await tester.enterText(find.byType(EditableText).last, 'salah123');
      await tester.tap(masukButton);
      await tester.pumpAndSettle();
    }

    testWidgets('401 shows the server message under the password field', (
      tester,
    ) async {
      await submitWith(
        tester,
        const AuthFailure('E-mail atau password salah.'),
      );
      expect(find.text('E-mail atau password salah.'), findsOneWidget);
      final password = tester.widget<AppTextField>(
        find.byType(AppTextField).last,
      );
      expect(password.errorText, 'E-mail atau password salah.');
    });

    testWidgets('429 shows the lockout banner', (tester) async {
      const message =
          'Akun Anda dikunci sementara karena beberapa kali kegagalan masuk. '
          'Silakan coba kembali dalam 15 menit.';
      await submitWith(tester, const ServerFailure(message, 429));
      expect(find.text(message), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });
  });

  testWidgets('Lupa password? opens the contact-admin sheet', (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(createWidgetUnderTest(MockLoginUseCase()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lupa password?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hubungi admin grup Anda'), findsOneWidget);
    await tester.tap(find.text('Mengerti'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hubungi admin grup Anda'), findsNothing);
  });
}
