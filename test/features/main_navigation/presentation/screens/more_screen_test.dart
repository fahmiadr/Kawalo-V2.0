import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/cubit/theme_mode_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawalo_mobile/features/auth/presentation/screens/group_selection_screen.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/screens/more_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

const _admin = UserGroupEntity(
  groupUid: 'g1',
  groupName: 'PT Kawalo Security',
  category: 'ADMIN',
  allowAdmin: true,
  allowPatrol: true,
  allowMonPatrol: false,
  features: [],
);
const _guard = UserGroupEntity(
  groupUid: 'g2',
  groupName: 'PT Maju Bersama',
  category: 'GUARD',
  allowAdmin: false,
  allowPatrol: true,
  allowMonPatrol: false,
  features: [],
);

UserEntity _user({required List<UserGroupEntity> groups}) => UserEntity(
  id: 'u1',
  email: 'zaki@kawalo.co.id',
  name: 'Ahmad Zaki',
  groups: groups,
  activeGroup: _admin,
);

void main() {
  late MockAuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(const LogoutRequested());
    PackageInfo.setMockInitialValues(
      appName: 'Kawalo',
      packageName: 'id.kawalo',
      version: '1.2.3',
      buildNumber: '45',
      buildSignature: '',
    );
  });

  setUp(() {
    authBloc = MockAuthBloc();
  });

  Future<void> pump(
    WidgetTester tester,
    AuthState state, {
    ThemeModeCubit? themeCubit,
  }) async {
    when(() => authBloc.state).thenReturn(state);
    // AuthBloc lives above the Navigator, as in MyApp, so pushed routes see it.
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          if (themeCubit != null)
            BlocProvider<ThemeModeCubit>.value(value: themeCubit),
        ],
        child: MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(body: MoreScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('theme selector defaults to Terang and switches the mode', (
    tester,
  ) async {
    final cubit = ThemeModeCubit(null);
    addTearDown(cubit.close);
    await pump(
      tester,
      Authenticated(user: _user(groups: [_admin])),
      themeCubit: cubit,
    );

    expect(find.text('Otomatis'), findsOneWidget);
    expect(find.text('Terang'), findsOneWidget);
    expect(cubit.state, ThemeMode.light);

    await tester.tap(find.text('Gelap'));
    await tester.pumpAndSettle();
    expect(cubit.state, ThemeMode.dark);

    await tester.tap(find.text('Otomatis'));
    await tester.pumpAndSettle();
    expect(cubit.state, ThemeMode.system);
  });

  testWidgets('hides the theme selector without a ThemeModeCubit', (
    tester,
  ) async {
    await pump(tester, Authenticated(user: _user(groups: [_admin])));

    expect(find.text('Gelap'), findsNothing);
  });

  testWidgets('renders profile, role, active group and app version', (
    tester,
  ) async {
    await pump(tester, Authenticated(user: _user(groups: [_admin, _guard])));

    expect(find.text('Ahmad Zaki'), findsOneWidget);
    expect(find.text('zaki@kawalo.co.id'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('PT Kawalo Security'), findsOneWidget);
    expect(find.text('AZ'), findsOneWidget);
    expect(find.text('Versi 1.2.3 (45)'), findsOneWidget);
  });

  testWidgets('Grup aktif text follows the dark color scheme', (tester) async {
    when(
      () => authBloc.state,
    ).thenReturn(Authenticated(user: _user(groups: [_admin])));
    // The Flutter Theme is not dark under M3EMaterialApp, so the text must
    // carry its own color instead of inheriting DefaultTextStyle.
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: M3EMaterialApp(
          data: AppTheme.m3eLight(),
          initialTheme: Brightness.dark,
          dynamicColoring: false,
          home: const Scaffold(body: MoreScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scheme = AppTheme.of(
      tester.element(find.byType(MoreScreen)),
    ).colorScheme;
    expect(scheme.brightness, Brightness.dark);

    Color? colorOf(String text) {
      return tester.widget<Text>(find.text(text)).style?.color;
    }

    expect(colorOf('Grup aktif'), scheme.onSurfaceVariant);
    expect(colorOf('PT Kawalo Security'), scheme.onSurface);
  });

  testWidgets('hides Ganti Grup when the user has a single group', (
    tester,
  ) async {
    await pump(tester, Authenticated(user: _user(groups: [_admin])));

    expect(find.text('Ganti Grup'), findsNothing);
    expect(find.text('Keluar'), findsOneWidget);
  });

  testWidgets('shows Ganti Grup when the user has more than one group', (
    tester,
  ) async {
    await pump(tester, Authenticated(user: _user(groups: [_admin, _guard])));

    expect(find.text('Ganti Grup'), findsOneWidget);
  });

  testWidgets('Ganti Grup opens the group selection screen', (tester) async {
    await pump(tester, Authenticated(user: _user(groups: [_admin, _guard])));

    await tester.tap(find.text('Ganti Grup'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupSelectionScreen), findsOneWidget);
    expect(find.text('PT Maju Bersama'), findsOneWidget);
  });

  testWidgets('back on the group picker cancels the switch without logout', (
    tester,
  ) async {
    await pump(tester, Authenticated(user: _user(groups: [_admin, _guard])));
    await tester.tap(find.text('Ganti Grup'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(AppIconButton),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GroupSelectionScreen), findsNothing);
    expect(find.byType(MoreScreen), findsOneWidget);
    verifyNever(() => authBloc.add(any()));
  });

  testWidgets('Keluar asks for confirmation before dispatching logout', (
    tester,
  ) async {
    await pump(tester, Authenticated(user: _user(groups: [_admin])));

    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(find.text('Keluar dari akun?'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    verifyNever(() => authBloc.add(any()));

    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar').last);
    await tester.pumpAndSettle();
    verify(() => authBloc.add(const LogoutRequested())).called(1);
  });
}
