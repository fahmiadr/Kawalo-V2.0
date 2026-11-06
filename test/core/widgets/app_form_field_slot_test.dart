import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_form_field_slot.dart';

void main() {
  Widget buildFrame({
    required Widget child,
    String label = 'Label Field',
    String? errorText,
  }) {
    return M3ETheme(
      data: AppTheme.m3eLight(),
      child: MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: Scaffold(
          body: AppFormFieldSlot(
            label: label,
            errorText: errorText,
            child: child,
          ),
        ),
      ),
    );
  }

  group('AppFormFieldSlot Tests', () {
    testWidgets('renders label and child without error when omitted',
        (tester) async {
      await tester.pumpWidget(
        buildFrame(
          label: 'Slot Label',
          child: const Text('Slot Child Content'),
        ),
      );

      expect(find.text('Slot Label'), findsOneWidget);
      expect(find.text('Slot Child Content'), findsOneWidget);
    });

    testWidgets('renders label and child', (tester) async {
      await tester.pumpWidget(
        buildFrame(
          label: 'Tipe Tamu *',
          child: const Text('Dropdown Slot'),
        ),
      );

      expect(find.text('Tipe Tamu *'), findsOneWidget);
      expect(find.text('Dropdown Slot'), findsOneWidget);
    });

    testWidgets('renders errorText when provided', (tester) async {
      await tester.pumpWidget(
        buildFrame(
          label: 'Tipe Tamu *',
          errorText: 'Wajib memilih tipe tamu',
          child: const Text('Dropdown Slot'),
        ),
      );

      expect(find.text('Tipe Tamu *'), findsOneWidget);
      expect(find.text('Wajib memilih tipe tamu'), findsOneWidget);
    });
  });
}
