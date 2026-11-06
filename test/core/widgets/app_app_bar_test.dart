import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_app_bar.dart';

void main() {
  group('AppAppBar / M3EAppBar Tests', () {
    testWidgets('renders top app bar with title and actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            appBar: AppAppBar.top(
              titleText: 'Kawalo App',
              actions: [
                IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: null,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Kawalo App'), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('supports bottom app bar variant', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            bottomNavigationBar: AppAppBar.bottom(
              actions: [
                IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: null,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.menu), findsOneWidget);
    });
  });
}
