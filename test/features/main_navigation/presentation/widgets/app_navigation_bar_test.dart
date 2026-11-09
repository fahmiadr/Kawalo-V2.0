import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/widgets/app_navigation_bar.dart';

void main() {
  group('AppNavigationBar / M3ENavigationBar Tests', () {
    testWidgets('renders destinations and responds to selection', (
      tester,
    ) async {
      var selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                bottomNavigationBar: AppNavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => selectedIndex = index);
                  },
                  destinations: const [
                    AppNavigationBarDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Beranda',
                    ),
                    AppNavigationBarDestination(
                      icon: Icon(Icons.info_outline),
                      selectedIcon: Icon(Icons.info),
                      label: 'Informasi',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Informasi'), findsOneWidget);

      await tester.tap(find.text('Informasi'));
      await tester.pumpAndSettle();

      expect(selectedIndex, equals(1));
    });
  });
}
