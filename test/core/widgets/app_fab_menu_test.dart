import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_fab.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: Scaffold(
        floatingActionButton: child,
      ),
    );
  }

  group('AppFabMenu Tests', () {
    testWidgets('renders anchor button when closed', (tester) async {
      await tester.pumpWidget(
        buildApp(
          AppFabMenu(
            items: [
              AppFabMenuItem(
                icon: const Icon(Icons.add),
                label: 'Add',
                onPressed: () {},
              ),
              AppFabMenuItem(
                icon: const Icon(Icons.remove),
                label: 'Remove',
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppFabMenu), findsOneWidget);
      expect(find.byType(M3EFabMenu), findsOneWidget);
    });

    testWidgets('tapping anchor opens menu and reveals menu items',
        (tester) async {
      var itemTapped = false;

      await tester.pumpWidget(
        buildApp(
          AppFabMenu(
            items: [
              AppFabMenuItem(
                icon: const Icon(Icons.email),
                label: 'Send Email',
                onPressed: () {
                  itemTapped = true;
                },
              ),
              AppFabMenuItem(
                icon: const Icon(Icons.phone),
                label: 'Call Support',
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially menu items are not visible in overlay
      expect(find.text('Send Email'), findsNothing);

      // Tap the anchor FAB
      final fabFinder = find.byType(M3EFab);
      expect(fabFinder, findsOneWidget);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Menu items are now visible
      expect(find.text('Send Email'), findsOneWidget);
      expect(find.text('Call Support'), findsOneWidget);

      // Tap an item
      await tester.tap(find.text('Send Email'));
      await tester.pumpAndSettle();

      expect(itemTapped, isTrue);
    });

    testWidgets('supports AppFabColor.error and custom overrides',
        (tester) async {
      const customBg = Color(0xFF990000);
      const customFg = Color(0xFFFFFFFF);

      await tester.pumpWidget(
        buildApp(
          AppFabMenu(
            color: AppFabColor.error,
            backgroundColor: customBg,
            foregroundColor: customFg,
            items: [
              AppFabMenuItem(
                icon: const Icon(Icons.warning),
                label: 'Alert',
                onPressed: () {},
              ),
              AppFabMenuItem(
                icon: const Icon(Icons.info),
                label: 'Info',
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppFabMenu), findsOneWidget);
      final m3eFabMenu = tester.widget<M3EFabMenu>(find.byType(M3EFabMenu));
      expect(
        m3eFabMenu.decoration?.backgroundColor?.resolve({}),
        equals(customBg),
      );
      expect(
        m3eFabMenu.decoration?.foregroundColor?.resolve({}),
        equals(customFg),
      );
    });
  });
}
