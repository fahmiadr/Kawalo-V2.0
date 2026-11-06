import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_shortcut_card.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_management_section.dart';

void main() {
  Widget buildTestWidget({
    VoidCallback? onEditPressed,
    VoidCallback? onAddPressed,
  }) {
    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: HomeManagementSection(
            onEditPressed: onEditPressed,
            onAddPressed: onAddPressed,
          ),
        ),
      ),
    );
  }

  group('HomeManagementSection Tests', () {
    testWidgets('renders all 5 management cards and 1 add management card',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Manajemen'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);

      // Card 1
      expect(find.text('Manajemen Shift'), findsOneWidget);
      // Card 2
      expect(find.text('Manajemen Jadwal'), findsOneWidget);
      // Card 3
      expect(find.text('Manajemen Personil'), findsOneWidget);
      // Card 4
      expect(find.text('Manajemen Grup'), findsOneWidget);
      expect(find.text('Grup Personil'), findsOneWidget);
      // Card 5
      expect(find.text('Laporan Bulanan'), findsOneWidget);
      expect(find.text('Otomatisasi Laporan'), findsOneWidget);
      expect(find.text('BARU!'), findsOneWidget);

      // Last Card: Tambah Manajemen
      expect(find.text('Tambah Manajemen'), findsOneWidget);
      expect(find.byType(AppShortcutCard), findsNWidgets(5));
      expect(find.byType(AppAddShortcutCard), findsOneWidget);
    });

    testWidgets('triggers callbacks for edit and add management',
        (tester) async {
      var editTapped = false;
      var addTapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          onEditPressed: () => editTapped = true,
          onAddPressed: () => addTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(editTapped, isTrue);

      await tester.tap(find.text('Tambah Manajemen'));
      await tester.pumpAndSettle();
      expect(addTapped, isTrue);
    });
  });
}
