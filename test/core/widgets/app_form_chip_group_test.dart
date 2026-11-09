import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_form_chip_group.dart';

void main() {
  Widget buildFrame({
    required List<AppFormChipItem<String?>> items,
    String label = 'Jenis Identitas',
    AppFormChipGroupLayout layout = AppFormChipGroupLayout.horizontalScroll,
    String? selectedValue,
    ValueChanged<String?>? onSelected,
    String? errorText,
    bool enabled = true,
  }) {
    return M3ETheme(
      data: AppTheme.m3eLight(),
      child: MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: Scaffold(
          body: AppFormChipGroup<String?>(
            label: label,
            layout: layout,
            items: items,
            selectedValue: selectedValue,
            onSelected: onSelected,
            errorText: errorText,
            enabled: enabled,
          ),
        ),
      ),
    );
  }

  group('AppFormChipGroup Tests', () {
    final testItems = [
      const AppFormChipItem<String?>(value: 'ktp', label: 'KTP'),
      const AppFormChipItem<String?>(value: 'sim', label: 'SIM'),
      const AppFormChipItem<String?>(value: 'paspor', label: 'Paspor'),
    ];

    testWidgets('renders all items and label in horizontalScroll mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildFrame(items: testItems, selectedValue: 'ktp'),
      );

      expect(find.text('Jenis Identitas'), findsOneWidget);
      expect(find.text('KTP'), findsOneWidget);
      expect(find.text('SIM'), findsOneWidget);
      expect(find.text('Paspor'), findsOneWidget);
    });

    testWidgets('invokes onSelected when tapping an unselected item', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        buildFrame(
          items: testItems,
          selectedValue: 'ktp',
          onSelected: (val) => selected = val,
        ),
      );

      await tester.tap(find.text('SIM'));
      await tester.pumpAndSettle();
      expect(selected, 'sim');
    });

    testWidgets('renders items in wrap mode', (tester) async {
      await tester.pumpWidget(
        buildFrame(layout: AppFormChipGroupLayout.wrap, items: testItems),
      );

      expect(find.byType(Wrap), findsOneWidget);
      expect(find.text('KTP'), findsOneWidget);
      expect(find.text('SIM'), findsOneWidget);
      expect(find.text('Paspor'), findsOneWidget);
    });

    testWidgets('renders errorText correctly', (tester) async {
      await tester.pumpWidget(
        buildFrame(
          items: testItems,
          errorText: 'Pilih salah satu jenis identitas',
        ),
      );

      expect(find.text('Pilih salah satu jenis identitas'), findsOneWidget);
    });

    testWidgets('treats sentinel item with null value as selected when '
        'selectedValue is null', (tester) async {
      final sentinelItems = [
        const AppFormChipItem<String?>(value: null, label: 'Tanpa Identitas'),
        const AppFormChipItem<String?>(value: 'ktp', label: 'KTP'),
      ];

      await tester.pumpWidget(buildFrame(items: sentinelItems));

      final tanpaIdentitasChip = tester.widget<AppChip>(
        find.widgetWithText(AppChip, 'Tanpa Identitas'),
      );
      final ktpChip = tester.widget<AppChip>(
        find.widgetWithText(AppChip, 'KTP'),
      );

      expect(tanpaIdentitasChip.selected, isTrue);
      expect(ktpChip.selected, isFalse);
    });
  });
}
