import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_tooltip.dart';

void main() {
  group('AppIconButton / M3EIconButton Tests', () {
    testWidgets('renders icon button and handles tap',
        (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: M3EIconButton(
              icon: const Icon(Icons.favorite),
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('supports toggle state',
        (WidgetTester tester) async {
      var isSelected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return M3EIconButton(
                  icon: const Icon(Icons.favorite_border),
                  selectedIcon: const Icon(Icons.favorite),
                  isSelected: isSelected,
                  onPressed: () => setState(() => isSelected = !isSelected),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();
      expect(isSelected, isTrue);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets(
      'renders badge and allows tapping directly on badge to trigger onPressed',
      (WidgetTester tester) async {
        var tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppIconButton(
                  icon: const Icon(Icons.notifications),
                  badgeValue: 5,
                  onPressed: () => tapped = true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('5'), findsOneWidget);
        expect(find.byType(AppIconButton), findsOneWidget);

        // Tap directly on badge text.
        await tester.tap(find.text('5'), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'supports custom badgeColor, badgeTextColor, and 99+ formatting',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppIconButton(
                  icon: Icon(Icons.notifications),
                  badgeValue: 120,
                  badgeColor: Colors.blue,
                  badgeTextColor: Colors.yellow,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('99+'), findsOneWidget);

        final badgeFinder = find.byType(Badge);
        expect(badgeFinder, findsOneWidget);
        final badgeWidget = tester.widget<Badge>(badgeFinder);
        expect(badgeWidget.backgroundColor, Colors.blue);
        expect(badgeWidget.textColor, Colors.yellow);
      },
    );

    testWidgets(
      'positions dot badge according to M3 guidelines and supports badgeOffset',
      (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                children: [
                  AppIconButton(
                    key: const ValueKey('default_dot_btn'),
                    icon: const Icon(Icons.filter_list),
                    badgeValue: true,
                    onPressed: () {},
                  ),
                  AppIconButton(
                    key: const ValueKey('filled_dot_btn'),
                    variant: AppIconButtonColor.filled,
                    icon: const Icon(Icons.filter_list),
                    badgeValue: true,
                    onPressed: () {},
                  ),
                  AppIconButton(
                    key: const ValueKey('custom_offset_btn'),
                    icon: const Icon(Icons.filter_list),
                    badgeValue: true,
                    badgeOffset: const Offset(6, 4),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final positionedWidgets = tester.widgetList<PositionedDirectional>(
        find.byType(PositionedDirectional),
      ).toList();

      expect(positionedWidgets.length, 3);
      // Standard variant: anchored to icon corner (top: 8.0, end: 8.0)
      expect(positionedWidgets[0].top, 8.0);
      expect(positionedWidgets[0].end, 8.0);

      // Filled variant: anchored to container corner (top: 0.0, end: 0.0)
      expect(positionedWidgets[1].top, 0.0);
      expect(positionedWidgets[1].end, 0.0);

      // Custom badge offset (dx: 6, dy: 4)
      expect(positionedWidgets[2].top, 4.0);
      expect(positionedWidgets[2].end, 6.0);
    });

    testWidgets(
      'positions value badge according to M3 guidelines anchored to icon',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  children: [
                    AppIconButton(
                      key: const ValueKey('standard_val_btn'),
                      icon: const Icon(Icons.notifications),
                      badgeValue: 5,
                      onPressed: () {},
                    ),
                    AppIconButton(
                      key: const ValueKey('filled_val_btn'),
                      variant: AppIconButtonColor.filled,
                      icon: const Icon(Icons.notifications),
                      badgeValue: 5,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final positionedWidgets = tester.widgetList<PositionedDirectional>(
          find.byType(PositionedDirectional),
        ).toList();

        expect(positionedWidgets.length, 2);
        // Standard variant value badge: anchored to icon (top: 4.0, end: 8.0)
        expect(positionedWidgets[0].top, 4.0);
        expect(positionedWidgets[0].end, 8.0);

        // Filled variant value badge: anchored to container (0.0, 0.0)
        expect(positionedWidgets[1].top, 0.0);
        expect(positionedWidgets[1].end, 0.0);
      },
    );

    testWidgets(
      'AppIconButton renders AppTooltip when tooltip is provided',
      (tester) async {
        await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppIconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Cari',
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.byType(AppTooltip), findsOneWidget);
      final tooltipWidget = tester.widget<AppTooltip>(find.byType(AppTooltip));
      expect(tooltipWidget.message, 'Cari');
    });
  });
}
