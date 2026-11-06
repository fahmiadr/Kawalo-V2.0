import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_dashboard_view.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_management_section.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_quick_actions.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_recent_guests_card.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_shortcuts_section.dart';

void main() {
  Widget buildTestWidget({
    VoidCallback? onAbsensiPressed,
    VoidCallback? onCheckpointPressed,
    VoidCallback? onEditShortcutsPressed,
    VoidCallback? onEditManagementPressed,
  }) {
    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: Scaffold(
        body: HomeDashboardView(
          onAbsensiPressed: onAbsensiPressed,
          onCheckpointPressed: onCheckpointPressed,
          onEditShortcutsPressed: onEditShortcutsPressed,
          onEditManagementPressed: onEditManagementPressed,
        ),
      ),
    );
  }

  group('HomeDashboardView & Modular Home Widgets Tests', () {
    testWidgets('renders all major sections on dashboard', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Memastikan HomeRecentGuestsCard tampil
      expect(find.byType(HomeRecentGuestsCard), findsOneWidget);
      expect(find.text('Tamu Terakhir'), findsOneWidget);
      expect(find.text('CN 10719'), findsOneWidget);

      // Memastikan HomeQuickActions tampil
      expect(find.byType(HomeQuickActions), findsOneWidget);
      expect(find.text('Absensi'), findsOneWidget);
      expect(find.text('Post to Post Checkpoint'), findsOneWidget);

      // Memastikan HomeShortcutsSection tampil
      expect(find.byType(HomeShortcutsSection), findsOneWidget);
      expect(find.text('Pintasan'), findsOneWidget);

      // Memastikan HomeManagementSection tampil
      expect(find.byType(HomeManagementSection), findsOneWidget);
      expect(find.text('Manajemen'), findsOneWidget);

      expect(find.text('Edit'), findsNWidgets(2));
      expect(find.byType(AppShortcutCard), findsWidgets);
    });

    testWidgets('triggers callbacks for quick actions', (tester) async {
      var absensiTapped = false;
      var checkpointTapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          onAbsensiPressed: () => absensiTapped = true,
          onCheckpointPressed: () => checkpointTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Absensi'));
      await tester.pumpAndSettle();
      expect(absensiTapped, isTrue);

      await tester.tap(find.text('Post to Post Checkpoint'));
      await tester.pumpAndSettle();
      expect(checkpointTapped, isTrue);
    });

    testWidgets('supports swiping on recent guests carousel', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('CN 10719'), findsOneWidget);

      // Swipe ke kiri untuk membuka halaman tamu berikutnya
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('B 1234 ABC'), findsOneWidget);
    });

    testWidgets('triggers edit callback on shortcuts and management sections',
        (tester) async {
      var editShortcutsTapped = false;
      var editManagementTapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          onEditShortcutsPressed: () => editShortcutsTapped = true,
          onEditManagementPressed: () => editManagementTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      final shortcutEdit = find.descendant(
        of: find.byType(HomeShortcutsSection),
        matching: find.text('Edit'),
      );
      await tester.tap(shortcutEdit);
      await tester.pumpAndSettle();
      expect(editShortcutsTapped, isTrue);

      final managementEdit = find.descendant(
        of: find.byType(HomeManagementSection),
        matching: find.text('Edit'),
      );
      await tester.ensureVisible(managementEdit);
      await tester.tap(managementEdit);
      await tester.pumpAndSettle();
      expect(editManagementTapped, isTrue);
    });
  });
}
