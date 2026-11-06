import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';

void main() {
  group('AppLoadingIndicator Tests', () {
    testWidgets('renders default morphing loading indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLoadingIndicator(),
          ),
        ),
      );

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
      final widget = tester.widget<AppLoadingIndicator>(
        find.byType(AppLoadingIndicator),
      );
      expect(widget.variant, AppLoadingIndicatorVariant.defaultStyle);
      expect(widget.size, AppLoadingIndicatorSize.medium);
    });

    testWidgets('renders contained variant loading indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLoadingIndicator(
              variant: AppLoadingIndicatorVariant.contained,
            ),
          ),
        ),
      );

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
      final widget = tester.widget<AppLoadingIndicator>(
        find.byType(AppLoadingIndicator),
      );
      expect(widget.variant, AppLoadingIndicatorVariant.contained);
    });

    testWidgets('supports small, medium, large, extraLarge size tokens',
        (tester) async {
      for (final size in AppLoadingIndicatorSize.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppLoadingIndicator(
                variant: AppLoadingIndicatorVariant.contained,
                size: size,
                semanticLabel: 'Loading ${size.name}',
              ),
            ),
          ),
        );

        final widget = tester.widget<AppLoadingIndicator>(
          find.byType(AppLoadingIndicator),
        );
        expect(widget.size, size);
        expect(widget.semanticLabel, 'Loading ${size.name}');
      }
    });

    test('size token values match M3 Expressive proportions', () {
      expect(AppLoadingIndicatorSize.small.containerSize, 36.0);
      expect(AppLoadingIndicatorSize.small.activeSize, 28.0);

      expect(AppLoadingIndicatorSize.medium.containerSize, 48.0);
      expect(AppLoadingIndicatorSize.medium.activeSize, 38.0);

      expect(AppLoadingIndicatorSize.large.containerSize, 64.0);
      expect(AppLoadingIndicatorSize.large.activeSize, 50.0);

      expect(AppLoadingIndicatorSize.extraLarge.containerSize, 72.0);
      expect(AppLoadingIndicatorSize.extraLarge.activeSize, 56.0);
    });
  });
}
