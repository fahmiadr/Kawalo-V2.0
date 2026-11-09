import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_text_link.dart';

void main() {
  Widget buildTestWidget({
    required String title,
    required String linkText,
    VoidCallback? onPressed,
  }) {
    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: Scaffold(
        body: AppTextLink(
          title: title,
          linkText: linkText,
          onPressed: onPressed,
        ),
      ),
    );
  }

  group('AppTextLink Widget Tests', () {
    testWidgets('renders title and linkText correctly', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(title: 'Pintasan', linkText: 'Edit'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pintasan'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('triggers onPressed callback when link is tapped', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          title: 'Text',
          linkText: 'Link',
          onPressed: () => tapped = true,
        ),
      );
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(AppTextLink));
      final colorScheme = AppTheme.of(element).colorScheme;
      final linkTextWidget = tester.widget<Text>(find.text('Link'));
      expect(linkTextWidget.style?.color, colorScheme.onSurface);

      await tester.tap(find.text('Link'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets(
      'renders title without action button when linkText is omitted',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: const Scaffold(body: AppTextLink(title: 'Data Laporan')),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Data Laporan'), findsOneWidget);
      },
    );

    testWidgets('renders link as disabled when onPressed is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(title: 'Filter pencarian', linkText: 'Reset'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Filter pencarian'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      final element = tester.element(find.byType(AppTextLink));
      final colorScheme = AppTheme.of(element).colorScheme;
      final expectedDisabledColor = colorScheme.onSurface.withValues(
        alpha: AppStateLayer.disabledOpacity,
      );
      final linkTextWidget = tester.widget<Text>(find.text('Reset'));
      expect(linkTextWidget.style?.color, expectedDisabledColor);

      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(
        button.decoration?.foregroundColor?.resolve({WidgetState.disabled}),
        expectedDisabledColor,
      );
    });
  });
}
