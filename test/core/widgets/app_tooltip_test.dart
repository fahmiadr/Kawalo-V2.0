import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/widgets/app_tooltip.dart';

void main() {
  group('AppTooltip / M3ETooltip Tests', () {
    testWidgets('renders child wrapped in tooltip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppTooltip(
                message: 'Tooltip Message',
                child: Icon(Icons.info),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AppTooltip), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('supports rich tooltip with richMessage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppTooltip(
                richTitle: 'Rich Title',
                richMessage: 'Rich Description',
                child: Icon(Icons.help),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AppTooltip), findsOneWidget);
      expect(find.byIcon(Icons.help), findsOneWidget);
    });
  });
}
