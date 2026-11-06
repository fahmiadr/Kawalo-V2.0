import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';

void main() {
  group('AppTappable Tests', () {
    testWidgets('renders child and handles onTap', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTappable(
              onTap: () => tapped = true,
              child: const Text('Tappable Content'),
            ),
          ),
        ),
      );

      expect(find.text('Tappable Content'), findsOneWidget);
      await tester.tap(find.text('Tappable Content'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('renders via AppTappable.builder and handles state',
        (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTappable.builder(
              onTap: () => tapped = true,
              builder: (context, state) {
                return Text(
                  state.pressed ? 'Pressed' : 'Idle',
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Idle'), findsOneWidget);
      await tester.tap(find.text('Idle'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('handles onLongPress callback', (WidgetTester tester) async {
      var longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTappable(
              onLongPress: () => longPressed = true,
              child: const Text('Long Press Me'),
            ),
          ),
        ),
      );

      await tester.longPress(find.text('Long Press Me'));
      await tester.pumpAndSettle();
      expect(longPressed, isTrue);
    });
  });
}
