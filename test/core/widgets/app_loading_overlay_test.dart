import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';

void main() {
  Widget wrapWithTheme(Widget child) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: Scaffold(body: child),
    );
  }

  group('AppLoadingOverlay Tests', () {
    testWidgets('renders in Stack with default medium contained indicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const Stack(
            children: [
              SizedBox.expand(child: Text('Background Content')),
              AppLoadingOverlay(semanticLabel: 'Memverifikasi akun'),
            ],
          ),
        ),
      );

      expect(find.byType(AppLoadingOverlay), findsOneWidget);

      final absorbPointerFinder = find.descendant(
        of: find.byType(AppLoadingOverlay),
        matching: find.byType(AbsorbPointer),
      );
      expect(absorbPointerFinder, findsOneWidget);

      final indicatorFinder = find.descendant(
        of: find.byType(AppLoadingOverlay),
        matching: find.byType(AppLoadingIndicator),
      );
      expect(indicatorFinder, findsOneWidget);

      final indicator = tester.widget<AppLoadingIndicator>(indicatorFinder);
      expect(indicator.variant, AppLoadingIndicatorVariant.contained);
      expect(indicator.size, AppLoadingIndicatorSize.medium);
      expect(indicator.elevation, 2.0);
      expect(indicator.semanticLabel, 'Memverifikasi akun');
    });

    testWidgets('renders optional message text inside card when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const Stack(
            children: [
              SizedBox.expand(child: Text('Background Content')),
              AppLoadingOverlay(
                semanticLabel: 'Sinkronisasi',
                message: 'Mohon tunggu sebentar...',
              ),
            ],
          ),
        ),
      );

      expect(find.text('Mohon tunggu sebentar...'), findsOneWidget);
      expect(find.byType(Material), findsWidgets);
    });

    testWidgets('renders child wrapper with overlay when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const AppLoadingOverlay(
            semanticLabel: 'Memuat data',
            child: SizedBox.expand(child: Text('Protected Content')),
          ),
        ),
      );

      expect(find.text('Protected Content'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppLoadingOverlay),
          matching: find.byType(AppLoadingIndicator),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AppLoadingOverlay),
          matching: find.byType(AbsorbPointer),
        ),
        findsOneWidget,
      );
    });

    testWidgets('child wrapper hides overlay when isLoading is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const AppLoadingOverlay(
            isLoading: false,
            semanticLabel: 'Memuat data',
            child: SizedBox.expand(child: Text('Protected Content')),
          ),
        ),
      );

      expect(find.text('Protected Content'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppLoadingOverlay),
          matching: find.byType(AppLoadingIndicator),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(AppLoadingOverlay),
          matching: find.byType(AbsorbPointer),
        ),
        findsNothing,
      );
    });

    testWidgets(
      'returns SizedBox.shrink when standalone and isLoading is false',
      (tester) async {
        await tester.pumpWidget(
          wrapWithTheme(
            const Stack(
              children: [
                SizedBox.expand(child: Text('Background Content')),
                AppLoadingOverlay(
                  isLoading: false,
                  semanticLabel: 'Tidak aktif',
                ),
              ],
            ),
          ),
        );

        expect(
          find.descendant(
            of: find.byType(AppLoadingOverlay),
            matching: find.byType(AppLoadingIndicator),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'supports non-positioned rendering when isPositioned is false',
      (tester) async {
        await tester.pumpWidget(
          wrapWithTheme(
            const Center(
              child: AppLoadingOverlay(
                isPositioned: false,
                semanticLabel: 'Dialog loading',
              ),
            ),
          ),
        );

        expect(find.byType(AppLoadingOverlay), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AppLoadingOverlay),
            matching: find.byType(AppLoadingIndicator),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
