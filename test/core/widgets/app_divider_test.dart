import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

void main() {
  group('AppDivider / M3EDivider Tests', () {
    testWidgets('renders horizontal divider', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: M3EDivider(),
          ),
        ),
      );

      expect(find.byType(M3EDivider), findsOneWidget);
    });

    testWidgets('renders vertical divider', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 100,
              child: M3EDivider(axis: M3EDividerAxis.vertical),
            ),
          ),
        ),
      );

      expect(find.byType(M3EDivider), findsOneWidget);
    });
  });
}
