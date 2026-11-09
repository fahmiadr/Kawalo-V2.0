import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';

void main() {
  Widget buildTestApp(Widget child) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: Scaffold(body: child),
    );
  }

  group('AppRefreshIndicator Tests', () {
    testWidgets('renders AppRefreshIndicator with child scrollable', (
      tester,
    ) async {
      var refreshed = false;

      await tester.pumpWidget(
        buildTestApp(
          AppRefreshIndicator(
            onRefresh: () async {
              refreshed = true;
            },
            child: ListView(
              children: const [
                ListTile(title: Text('Item 1')),
                ListTile(title: Text('Item 2')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppRefreshIndicator), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);

      // Trigger pull to refresh gesture
      await tester.fling(find.text('Item 1'), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(refreshed, isTrue);
    });

    testWidgets('AppRefreshIndicator.contained renders contained variant', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          AppRefreshIndicator.contained(
            onRefresh: () async {},
            child: ListView(children: const [Text('Scrollable content')]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppRefreshIndicator), findsOneWidget);
      expect(find.text('Scrollable content'), findsOneWidget);
    });
  });
}
