import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/widgets/app_badge.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

void main() {
  group('AppBadge / M3EBadge Tests', () {
    testWidgets('renders badge with count', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: M3EBadge(
              count: 5,
              child: Icon(Icons.notifications),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders dot badge when showDot is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: M3EBadge(
              showDot: true,
              child: Icon(Icons.notifications),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });
  });
}
