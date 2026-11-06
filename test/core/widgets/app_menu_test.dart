import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_menu.dart';

void main() {
  Widget buildTestApp(Widget child) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('AppMenu Tests', () {
    testWidgets('AppMenu opens popup menu and selects item', (tester) async {
      String? selectedOption;

      await tester.pumpWidget(
        buildTestApp(
          AppMenu(
            anchorBuilder: (context, open) => ElevatedButton(
              onPressed: open,
              child: const Text('Open Menu'),
            ),
            entries: [
              AppMenuEntry(
                label: 'Option 1',
                value: 'opt_1',
                onPressed: () {
                  selectedOption = 'opt_1';
                },
              ),
              AppMenuEntry(
                label: 'Option 2',
                value: 'opt_2',
                onPressed: () {
                  selectedOption = 'opt_2';
                },
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open menu
      await tester.tap(find.text('Open Menu'));
      await tester.pumpAndSettle();

      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);

      // Select option 1
      await tester.tap(find.text('Option 1'));
      await tester.pumpAndSettle();

      expect(selectedOption, equals('opt_1'));
    });
  });
}
