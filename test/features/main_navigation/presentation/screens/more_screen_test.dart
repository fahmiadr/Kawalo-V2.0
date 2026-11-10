import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
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

  Future<void> pump(WidgetTester tester, AuthState state) async {
    when(() => authBloc.state).thenReturn(state);
    // AuthBloc lives above the Navigator, as in MyApp, so pushed routes see it.
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(body: MoreScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

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
