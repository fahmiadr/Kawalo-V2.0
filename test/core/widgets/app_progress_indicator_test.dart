import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/widgets/app_progress_indicator.dart';

void main() {
  group('AppProgressIndicator / M3EProgressIndicator Tests', () {
    testWidgets('renders circular progress indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppProgressIndicator.circular(value: 0.5),
          ),
        ),
      );

      expect(find.byType(AppProgressIndicator), findsOneWidget);
    });

    testWidgets('renders linear progress indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppProgressIndicator.linear(value: 0.75),
          ),
        ),
      );

      expect(find.byType(AppProgressIndicator), findsOneWidget);
    });

    testWidgets('renders wavy progress indicator variants', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppProgressIndicator.circularWavy(value: 0.5),
                AppProgressIndicator.linearWavy(value: 0.5),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(AppProgressIndicator), findsNWidgets(2));
    });
  });
}
