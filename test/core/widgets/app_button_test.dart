import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

void main() {
  group('AppButton / M3EButton Tests', () {
    testWidgets('renders button with label and handles tap', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: M3EButton(
              onPressed: () => tapped = true,
              child: const Text('Save'),
            ),
          ),
        ),
      );

      expect(find.text('Save'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('renders button with icon and label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: M3EButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ),
        ),
      );

      expect(find.text('Add'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('does not trigger tap when enabled is false', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: M3EButton(
              enabled: false,
              onPressed: () => tapped = true,
              child: const Text('Disabled'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Disabled'));
      await tester.pumpAndSettle();
      expect(tapped, isFalse);
    });
  });
}
