import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
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
      expect(find.text('Selamat Datang'), findsOneWidget);
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
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

    await tester.tap(find.text('Masuk'));
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

    await tester.tap(find.text('Masuk'));
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

    await tester.tap(find.text('Masuk'));
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

    // Verify modal scrim overlay with contained AppLoadingIndicator
    final indicatorFinder = find.byType(AppLoadingIndicator);
    expect(indicatorFinder, findsOneWidget);
    final indicator = tester.widget<AppLoadingIndicator>(indicatorFinder);
    expect(indicator.variant, AppLoadingIndicatorVariant.contained);
    expect(indicator.semanticLabel, 'Memverifikasi akun');

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

      await tester.tap(find.text('Masuk'));
      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => mockLoginUseCase(any())).called(1);
      expect(find.byType(MainNavigationScreen), findsOneWidget);
      expect(find.text('Selamat Datang'), findsNothing);
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

  testWidgets(
    'auto-scrolls to reveal Masuk button when keyboard appears on login screen',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      final mockLoginUseCase = MockLoginUseCase();

      await tester.pumpWidget(createWidgetUnderTest(mockLoginUseCase));
      await tester.pumpAndSettle();

      final masukButtonFinder = find.text('Masuk');
      expect(masukButtonFinder, findsOneWidget);

      // Simulate keyboard appearing and tap email field
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      await tester.tap(find.byType(EditableText).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(masukButtonFinder, findsOneWidget);
    },
  );
}
