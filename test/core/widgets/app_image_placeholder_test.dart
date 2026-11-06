import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_shape.dart';
import 'package:kawalo_mobile/core/widgets/app_image_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

void main() {
  testWidgets(
    'AppImagePlaceholder renders label and default icon correctly',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppImagePlaceholder(
              label: 'Avatar Placeholder',
            ),
          ),
        ),
      );

      expect(find.text('Avatar Placeholder'), findsOneWidget);
    },
  );

  testWidgets(
    'AppImagePlaceholder renders custom icon widget correctly',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppImagePlaceholder(
              label: 'Custom Icon',
              icon: Icon(Icons.person),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.text('Custom Icon'), findsOneWidget);
    },
  );

  testWidgets(
    'AppImagePlaceholder renders without label properly without extra gap',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppImagePlaceholder(),
          ),
        ),
      );

      expect(find.byType(Text), findsNothing);
      expect(find.byType(AppImagePlaceholder), findsOneWidget);
    },
  );

  testWidgets(
    'AppImagePlaceholder uses AppShape tokens properly',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppImagePlaceholder(
              label: 'Shape Test',
              shape: AppShape.full,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppImagePlaceholder),
          matching: find.byType(Container),
        ),
      );

      expect(container.decoration, isA<ShapeDecoration>());
      expect(
        (container.decoration! as ShapeDecoration).shape,
        AppShape.full,
      );
    },
  );

  testWidgets(
    'AppImagePlaceholder applies custom backgroundColor and foregroundColor',
    (WidgetTester tester) async {
      const customBg = Colors.purple;
      const customFg = Colors.yellow;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppImagePlaceholder(
              label: 'Color Test',
              backgroundColor: customBg,
              foregroundColor: customFg,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppImagePlaceholder),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration! as ShapeDecoration;
      expect(decoration.color, customBg);

      final iconWidget = tester.widget<AppSvgIcon>(
        find.descendant(
          of: find.byType(AppImagePlaceholder),
          matching: find.byType(AppSvgIcon),
        ),
      );
      expect(iconWidget.color, customFg);
    },
  );

  testWidgets(
    'AppImagePlaceholder provides accessible semantics without duplicate '
    'announcements',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppImagePlaceholder(
              label: 'Foto Profil',
              semanticLabel: 'Placeholder Foto Profil Pengguna',
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Placeholder Foto Profil Pengguna'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'AppImagePlaceholder applies iconSize to AppSvgIcon properly',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppImagePlaceholder(
              iconPath: 'assets/icons/vector/image-not-found-01.svg',
              iconSize: 60,
            ),
          ),
        ),
      );

      final iconWidget = tester.widget<AppSvgIcon>(
        find.descendant(
          of: find.byType(AppImagePlaceholder),
          matching: find.byType(AppSvgIcon),
        ),
      );
      expect(iconWidget.size, 60);
      expect(iconWidget.fit, BoxFit.contain);
    },
  );
}
