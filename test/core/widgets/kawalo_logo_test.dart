import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/kawalo_logo.dart';

void main() {
  Widget buildTestApp(Widget child) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('KawaloLogoText Widget Tests', () {
    testWidgets('renders default logo with correct semantic label',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const KawaloLogoText()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(KawaloLogoText), findsOneWidget);
      expect(find.byType(FittedBox), findsNothing);

      final semantics = tester.getSemantics(find.byType(KawaloLogoText));
      expect(semantics.label, equals('Kawalo'));
      expect(semantics.flagsCollection.isHeader, isTrue);
    });

    testWidgets('respects custom fontSize and custom semanticLabel',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const KawaloLogoText(
            fontSize: 48,
            semanticLabel: 'KAWALO_BRAND',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(find.byType(KawaloLogoText));
      expect(semantics.label, equals('KAWALO_BRAND'));
    });

    testWidgets(
      'scales down gracefully in narrow constraint when fit is provided',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            const SizedBox(
              width: 50,
              height: 24,
              child: KawaloLogoText(
                fontSize: 76,
                fit: BoxFit.scaleDown,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(KawaloLogoText), findsOneWidget);
    });

    testWidgets('respects custom textScaler override',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const KawaloLogoText(
            textScaler: TextScaler.noScaling,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.textScaler, equals(TextScaler.noScaling));
    });

    testWidgets('supports custom colors for text and accent W',
        (WidgetTester tester) async {
      const textColor = Color(0xFF112233);
      const primaryColor = Color(0xFF445566);

      await tester.pumpWidget(
        buildTestApp(
          const KawaloLogoText(
            textColor: textColor,
            primaryColor: primaryColor,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.byType(Text));
      final rootSpan = textWidget.textSpan! as TextSpan;

      expect(rootSpan.children, isNotNull);
      expect(rootSpan.children!.length, equals(3));

      final kaSpan = rootSpan.children![0] as TextSpan;
      final wSpan = rootSpan.children![1] as TextSpan;
      final alSpan = rootSpan.children![2] as TextSpan;

      expect(kaSpan.text, equals('KA'));
      expect(kaSpan.style?.color, equals(textColor));

      expect(wSpan.text, equals('W'));
      expect(wSpan.style?.color, equals(primaryColor));

      expect(alSpan.text, equals('ALO'));
      expect(alSpan.style?.color, equals(textColor));
    });
  });
}
