import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_shortcuts_section.dart';

import '../../../attendance_admin/fixtures.dart';

void main() {
  Future<void> pump(WidgetTester tester, String role) async {
    await tester.pumpWidget(
      BlocProvider<UserSessionCubit>.value(
        value: UserSessionCubit(session(role)),
        child: MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: SingleChildScrollView(child: HomeShortcutsSection()),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('admins get the Pengaturan Absensi shortcut', (tester) async {
    await pump(tester, 'ADMIN');
    expect(find.text('Pengaturan Absensi'), findsOneWidget);
  });

  testWidgets('guards do not see it', (tester) async {
    await pump(tester, 'GUARD');
    expect(find.text('Pengaturan Absensi'), findsNothing);
  });
}
