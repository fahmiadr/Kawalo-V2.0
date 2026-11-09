import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_selection.dart';

void main() {
  group('AppSelectionAppBar Tests', () {
    testWidgets(
      'preferredSize reflects idle preferredSize correctly for 140dp & 64dp',
      (tester) async {
        final controller = AppSelectionController();

        // 1. With search bar: 64 + 76 = 140dp
        const idleWithSearch = AppHomeAppBar(
          title: 'Pusat informasi',
          searchBar: SizedBox(height: 48),
        );
        final appBarWithSearch = AppSelectionAppBar(
          idle: idleWithSearch,
          controller: controller,
        );
        expect(appBarWithSearch.preferredSize.height, equals(140.0));

        // 2. Without search bar: 64dp
        const idleWithoutSearch = AppHomeAppBar(title: 'Pusat informasi');
        final appBarWithoutSearch = AppSelectionAppBar(
          idle: idleWithoutSearch,
          controller: controller,
        );
        expect(appBarWithoutSearch.preferredSize.height, equals(64.0));
      },
    );

    testWidgets('renders idle bar when not in selection mode', (tester) async {
      final controller = AppSelectionController();
      const idle = AppHomeAppBar(title: 'Data Berita');

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              M3ETheme(data: AppTheme.m3eLight(), child: child!),
          home: Scaffold(
            appBar: AppSelectionAppBar(idle: idle, controller: controller),
            body: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Data Berita'), findsOneWidget);
    });

    testWidgets('switches to contextual mode and displays selected count', (
      tester,
    ) async {
      final controller = AppSelectionController();
      const idle = AppHomeAppBar(title: 'Data Berita');

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              M3ETheme(data: AppTheme.m3eLight(), child: child!),
          home: Scaffold(
            appBar: AppSelectionAppBar(
              idle: idle,
              controller: controller,
              itemCount: 5,
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller
        ..select(0)
        ..select(2);
      await tester.pumpAndSettle();

      // Counter '2' appears in contextual toolbar
      expect(find.text('2'), findsOneWidget);

      // Clear selection via controller
      controller.clear();
      await tester.pumpAndSettle();

      expect(find.text('Data Berita'), findsOneWidget);
    });
  });
}
