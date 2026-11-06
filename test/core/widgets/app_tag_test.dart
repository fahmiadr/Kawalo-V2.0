import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';

Widget _buildTestApp(Widget child) {
  return M3EMaterialApp(
    data: AppTheme.m3eLight(),
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}

void main() {
  group('AppTag Widget Tests', () {
    testWidgets('renders label text correctly', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const AppTag(label: 'Test Tag'),
        ),
      );

      expect(find.text('Test Tag'), findsOneWidget);
    });

    testWidgets('renders all semantic variants with correct M3 colors',
        (tester) async {
      for (final variant in AppTagVariant.values) {
        await tester.pumpWidget(
          _buildTestApp(
            AppTag(
              label: variant.name,
              variant: variant,
            ),
          ),
        );

        final textFinder = find.text(variant.name);
        expect(textFinder, findsOneWidget);

        final BuildContext context = tester.element(textFinder);
        final colorScheme = AppTheme.colorSchemeOf(context);

        final decoratedBox = tester.widget<DecoratedBox>(
          find.byType(DecoratedBox).first,
        );
        final decoration = decoratedBox.decoration as BoxDecoration;
        final textWidget = tester.widget<Text>(textFinder);

        switch (variant) {
          case AppTagVariant.primary:
            expect(decoration.color, colorScheme.primaryContainer);
            expect(textWidget.style?.color, colorScheme.onPrimaryContainer);
          case AppTagVariant.secondary:
            expect(decoration.color, colorScheme.secondaryContainer);
            expect(textWidget.style?.color, colorScheme.onSecondaryContainer);
          case AppTagVariant.tertiary:
            expect(decoration.color, colorScheme.tertiaryContainer);
            expect(textWidget.style?.color, colorScheme.onTertiaryContainer);
          case AppTagVariant.error:
            expect(decoration.color, colorScheme.errorContainer);
            expect(textWidget.style?.color, colorScheme.onErrorContainer);
          case AppTagVariant.neutral:
            expect(decoration.color, colorScheme.surfaceContainerHighest);
            expect(textWidget.style?.color, colorScheme.onSurfaceVariant);
        }
      }
    });

    testWidgets('renders outlined style with transparent background and border',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const AppTag(
            label: 'Outlined Tag',
            isOutlined: true,
          ),
        ),
      );

      final decoratedBox = tester.widget<DecoratedBox>(
        find.byType(DecoratedBox).first,
      );
      final decoration = decoratedBox.decoration as BoxDecoration;

      expect(decoration.color, Colors.transparent);
      expect(decoration.border, isNotNull);
    });

    testWidgets('respects custom color overrides', (tester) async {
      const customBg = Color(0xFF123456);
      const customFg = Color(0xFF654321);
      const customBorder = Color(0xFFABCDEF);

      await tester.pumpWidget(
        _buildTestApp(
          const AppTag(
            label: 'Custom Colors',
            backgroundColor: customBg,
            textColor: customFg,
            borderColor: customBorder,
          ),
        ),
      );

      final decoratedBox = tester.widget<DecoratedBox>(
        find.byType(DecoratedBox).first,
      );
      final decoration = decoratedBox.decoration as BoxDecoration;
      final textWidget = tester.widget<Text>(find.text('Custom Colors'));

      expect(decoration.color, customBg);
      expect(textWidget.style?.color, customFg);
      expect(decoration.border?.top.color, customBorder);
    });

    testWidgets('renders leading and trailing widgets correctly',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const AppTag(
            label: 'With Icons',
            leading: Icon(Icons.check, key: Key('leading-icon')),
            trailing: Icon(Icons.close, key: Key('trailing-icon')),
          ),
        ),
      );

      expect(find.byKey(const Key('leading-icon')), findsOneWidget);
      expect(find.text('With Icons'), findsOneWidget);
      expect(find.byKey(const Key('trailing-icon')), findsOneWidget);
    });

    testWidgets('renders different size variants', (tester) async {
      for (final size in AppTagSize.values) {
        await tester.pumpWidget(
          _buildTestApp(
            AppTag(
              label: 'Size ${size.name}',
              size: size,
            ),
          ),
        );

        expect(find.text('Size ${size.name}'), findsOneWidget);
      }
    });

    testWidgets('respects custom borderRadius', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const AppTag(
            label: 'Rounded Rect',
            borderRadius: AppRadius.borderSmall,
          ),
        ),
      );

      final decoratedBox = tester.widget<DecoratedBox>(
        find.byType(DecoratedBox).first,
      );
      final decoration = decoratedBox.decoration as BoxDecoration;

      expect(decoration.borderRadius, AppRadius.borderSmall);
    });

    testWidgets('provides correct semantics label', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const AppTag(
            label: 'Visible Label',
            semanticLabel: 'Custom Accessible Description',
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Custom Accessible Description'),
        findsOneWidget,
      );
    });
  });
}
