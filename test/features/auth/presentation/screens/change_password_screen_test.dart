import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_page_actions.dart';
import 'package:kawalo_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawalo_mobile/features/auth/presentation/cubit/change_password_cubit.dart';
import 'package:kawalo_mobile/features/auth/presentation/screens/change_password_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  late _MockAuthRepository repository;
  late _MockAuthBloc authBloc;

  setUpAll(() => registerFallbackValue(const LogoutRequested()));

  setUp(() {
    repository = _MockAuthRepository();
    authBloc = _MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthInitial());
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ChangePasswordCubit(repository)),
            BlocProvider<AuthBloc>.value(value: authBloc),
          ],
          child: const ChangePasswordScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fill(
    WidgetTester tester, {
    String current = 'password-lama',
    String newPassword = 'password-baru',
    String repeat = 'password-baru',
  }) async {
    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), current);
    await tester.enterText(fields.at(1), newPassword);
    await tester.enterText(fields.at(2), repeat);
    await tester.pump();
  }

  bool simpanEnabled(WidgetTester tester) => tester
      .widget<AppButton>(
        find.descendant(
          of: find.byType(AppPageActions),
          matching: find.byType(AppButton),
        ),
      )
      .enabled;

  void stubChange(Either<Failure, void> result) => when(
    () => repository.changePassword(
      currentPassword: any(named: 'currentPassword'),
      newPassword: any(named: 'newPassword'),
    ),
  ).thenAnswer((_) async => result);

  testWidgets('Simpan is at the bottom, never in the header', (tester) async {
    await pump(tester);

    expect(
      find.descendant(
        of: find.byType(AppHomeAppBar),
        matching: find.text('Simpan'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(AppPageActions),
        matching: find.text('Simpan'),
      ),
      findsOneWidget,
    );
    expect(find.text('Ganti Password'), findsOneWidget);
    expect(find.text('Password saat ini'), findsOneWidget);
    expect(find.text('Password baru'), findsOneWidget);
    expect(find.text('Ulangi password baru'), findsOneWidget);
  });

  testWidgets('Simpan stays disabled until the form is valid', (tester) async {
    await pump(tester);
    expect(simpanEnabled(tester), isFalse);

    await fill(tester, newPassword: 'pendek', repeat: 'pendek');
    expect(simpanEnabled(tester), isFalse);
    expect(find.text('Password baru minimal 8 karakter.'), findsOneWidget);

    await fill(tester, repeat: 'beda-sekali');
    expect(simpanEnabled(tester), isFalse);
    expect(
      find.text('Ulangi password tidak sama dengan password baru.'),
      findsOneWidget,
    );

    await fill(tester, newPassword: 'password-lama', repeat: 'password-lama');
    expect(simpanEnabled(tester), isFalse);
    expect(
      find.text('Password baru harus berbeda dari password saat ini.'),
      findsOneWidget,
    );

    await fill(tester);
    expect(simpanEnabled(tester), isTrue);
  });

  testWidgets('wrong current password (403) shows under that field only', (
    tester,
  ) async {
    stubChange(
      const Left(
        ServerFailure(
          'Password saat ini salah.',
          403,
          'AUTH_INVALID_CREDENTIALS',
        ),
      ),
    );
    await pump(tester);
    await fill(tester);

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Password saat ini salah.'), findsOneWidget);
    verifyNever(() => authBloc.add(any()));

    // Editing the field clears the server error again.
    await tester.enterText(find.byType(EditableText).at(0), 'coba-lagi');
    await tester.pump();
    expect(find.text('Password saat ini salah.'), findsNothing);
  });

  testWidgets('another error is shown as a message and does not log out', (
    tester,
  ) async {
    stubChange(const Left(ServerFailure('Password baru terlalu lemah.', 422)));
    await pump(tester);
    await fill(tester);

    await tester.tap(find.text('Simpan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Password baru terlalu lemah.'), findsOneWidget);
    verifyNever(() => authBloc.add(any()));
    await tester.pumpAndSettle(const Duration(seconds: 6));
  });

  testWidgets('success signs the user out with a message for the login', (
    tester,
  ) async {
    stubChange(const Right(null));
    await pump(tester);
    await fill(tester);

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    verify(
      () => repository.changePassword(
        currentPassword: 'password-lama',
        newPassword: 'password-baru',
      ),
    ).called(1);
    verify(
      () => authBloc.add(
        const LogoutRequested(
          message: 'Password berhasil diubah. Silakan masuk kembali.',
        ),
      ),
    ).called(1);
  });
}
