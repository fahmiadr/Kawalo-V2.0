import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_dialog.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/screens/guest_screen.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_shortcuts_section.dart';

import '../../../../helpers/mock_screen_cubits.dart';

void main() {
  Widget buildTestWidget({
    VoidCallback? onEditPressed,
    VoidCallback? onAddPressed,
    VoidCallback? onLogoutPressed,
  }) {
    return BlocProvider<GuestCubit>.value(
      value: createStubbedGuestCubit(),
      child: MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeShortcutsSection(
              onEditPressed: onEditPressed,
              onAddPressed: onAddPressed,
              onLogoutPressed: onLogoutPressed,
            ),
          ),
        ),
      ),
    );
  }

  group('HomeShortcutsSection Tests', () {
    testWidgets('renders all shortcut items including Logout', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Pintasan'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
      expect(find.text('Keluar Akun'), findsOneWidget);
    });

    testWidgets('tapping Logout opens confirmation dialog', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final logoutCard = find.text('Logout');
      await tester.ensureVisible(logoutCard);
      await tester.tap(logoutCard);
      await tester.pumpAndSettle();

      // Dialog konfirmasi harus muncul
      final dialogFinder = find.byType(AppConfirmationDialog);
      expect(dialogFinder, findsOneWidget);
      expect(
        find.descendant(
          of: dialogFinder,
          matching: find.text('Keluar dari akun?'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialogFinder,
          matching: find.text(
            'Sesi Anda akan berakhir. Anda perlu masuk kembali '
            'untuk mengakses aplikasi.',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialogFinder, matching: find.text('Batal')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialogFinder, matching: find.text('Keluar')),
        findsOneWidget,
      );
    });

    testWidgets('tapping Batal in logout dialog dismisses dialog', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final logoutCard = find.text('Logout');
      await tester.ensureVisible(logoutCard);
      await tester.tap(logoutCard);
      await tester.pumpAndSettle();

      expect(find.byType(AppConfirmationDialog), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.byType(AppConfirmationDialog), findsNothing);
    });

    testWidgets('custom onLogoutPressed callback is called when provided', (
      tester,
    ) async {
      var logoutTapped = false;

      await tester.pumpWidget(
        buildTestWidget(onLogoutPressed: () => logoutTapped = true),
      );
      await tester.pumpAndSettle();

      final logoutCard = find.text('Logout');
      await tester.ensureVisible(logoutCard);
      await tester.tap(logoutCard);
      await tester.pumpAndSettle();

      expect(logoutTapped, isTrue);
      // Dialog tidak muncul karena callback kustom yang menangani
      expect(find.byType(AppConfirmationDialog), findsNothing);
    });

    testWidgets('tapping Data Tamu navigates to GuestScreen', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final guestCard = find.text('Data Tamu');
      await tester.ensureVisible(guestCard);
      await tester.tap(guestCard);
      await tester.pumpAndSettle();

      expect(find.byType(GuestScreen), findsOneWidget);
    });
  });
}
