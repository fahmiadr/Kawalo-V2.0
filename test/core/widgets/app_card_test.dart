import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

void main() {
  group('AppCard / M3ECard Tests', () {
    testWidgets('renders card child and handles onPressed', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: M3ECard(
              onPressed: () => tapped = true,
              child: const Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      await tester.tap(find.text('Card Content'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('renders outlined card variant', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: M3ECard(
              variant: M3ECardVariant.outlined,
              child: Text('Outlined Card'),
            ),
          ),
        ),
      );

      expect(find.text('Outlined Card'), findsOneWidget);
    });
  });
}
