import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_fab.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: Scaffold(floatingActionButton: child),
    );
  }

  group('AppExtendedFab & AppFab M3E Tests', () {
    testWidgets('AppExtendedFab renders label and icon correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          AppExtendedFab(
            onPressed: () {},
            color: AppFabColor.tertiary,
            icon: const Icon(Icons.warning),
            label: 'SOS',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SOS'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('AppFab renders icon correctly', (tester) async {
      await tester.pumpWidget(
        buildApp(
          AppFab(
            onPressed: () {},
            color: AppFabColor.secondary,
            icon: const Icon(Icons.add),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('AppFab with AppFabColor.error resolves error colors', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          AppFab(
            onPressed: () {},
            color: AppFabColor.error,
            icon: const Icon(Icons.error),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error), findsOneWidget);
      final m3eFabFinder = find.byType(M3EFab);
      expect(m3eFabFinder, findsOneWidget);

      final m3eFab = tester.widget<M3EFab>(m3eFabFinder);
      expect(m3eFab.decoration?.backgroundColor, isNotNull);
      expect(m3eFab.decoration?.foregroundColor, isNotNull);
    });

    testWidgets('AppExtendedFab with AppFabColor.error resolves error colors', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          AppExtendedFab(
            onPressed: () {},
            color: AppFabColor.error,
            icon: const Icon(Icons.error),
            label: 'Error Alert',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Error Alert'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);

      final m3eExtendedFabFinder = find.byType(M3EExtendedFab);
      expect(m3eExtendedFabFinder, findsOneWidget);

      final m3eExtendedFab = tester.widget<M3EExtendedFab>(
        m3eExtendedFabFinder,
      );
      expect(m3eExtendedFab.decoration?.backgroundColor, isNotNull);
      expect(m3eExtendedFab.decoration?.foregroundColor, isNotNull);
    });

    testWidgets('AppFab with custom backgroundColor & foregroundColor applies '
        'overrides', (tester) async {
      const customBg = Color(0xFF123456);
      const customFg = Color(0xFF654321);

      await tester.pumpWidget(
        buildApp(
          AppFab(
            onPressed: () {},
            backgroundColor: customBg,
            foregroundColor: customFg,
            icon: const Icon(Icons.star),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final m3eFabFinder = find.byType(M3EFab);
      expect(m3eFabFinder, findsOneWidget);

      final m3eFab = tester.widget<M3EFab>(m3eFabFinder);
      expect(m3eFab.decoration?.backgroundColor?.resolve({}), equals(customBg));
      expect(m3eFab.decoration?.foregroundColor?.resolve({}), equals(customFg));
    });

    testWidgets('AppExtendedFab with custom backgroundColor & foregroundColor '
        'applies overrides', (tester) async {
      const customBg = Color(0xFF112233);
      const customFg = Color(0xFF445566);

      await tester.pumpWidget(
        buildApp(
          AppExtendedFab(
            onPressed: () {},
            backgroundColor: customBg,
            foregroundColor: customFg,
            icon: const Icon(Icons.bookmark),
            label: 'Custom Colors',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final m3eExtendedFabFinder = find.byType(M3EExtendedFab);
      expect(m3eExtendedFabFinder, findsOneWidget);

      final m3eExtendedFab = tester.widget<M3EExtendedFab>(
        m3eExtendedFabFinder,
      );
      expect(
        m3eExtendedFab.decoration?.backgroundColor?.resolve({}),
        equals(customBg),
      );
      expect(
        m3eExtendedFab.decoration?.foregroundColor?.resolve({}),
        equals(customFg),
      );
    });

    testWidgets('AppFabMenu renders with custom colors correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          AppFabMenu(
            color: AppFabColor.error,
            items: [
              AppFabMenuItem(
                icon: const Icon(Icons.mail),
                label: 'Mail',
                onPressed: () {},
              ),
              AppFabMenuItem(
                icon: const Icon(Icons.phone),
                label: 'Phone',
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(M3EFabMenu), findsOneWidget);
    });

    test('AppStationaryEndFloatFabLocation computes fixed offsets', () {
      const location = AppStationaryEndFloatFabLocation(
        bottomOffset: 20,
        endOffset: 24,
      );

      const ltrGeometry = ScaffoldPrelayoutGeometry(
        bottomSheetSize: Size.zero,
        contentBottom: 500,
        contentTop: 80,
        floatingActionButtonSize: Size(56, 56),
        minInsets: EdgeInsets.only(bottom: 300),
        minViewPadding: EdgeInsets.only(bottom: 48),
        scaffoldSize: Size(400, 800),
        snackBarSize: Size.zero,
        materialBannerSize: Size.zero,
        textDirection: TextDirection.ltr,
      );

      final ltrOffset = location.getOffset(ltrGeometry);
      expect(ltrOffset.dx, equals(400 - 56 - 24));
      // 800 - 56 - 48 (safe area) - 20
      expect(ltrOffset.dy, equals(800 - 56 - 48 - 20));

      const rtlGeometry = ScaffoldPrelayoutGeometry(
        bottomSheetSize: Size.zero,
        contentBottom: 500,
        contentTop: 80,
        floatingActionButtonSize: Size(56, 56),
        minInsets: EdgeInsets.only(bottom: 300),
        minViewPadding: EdgeInsets.only(bottom: 48),
        scaffoldSize: Size(400, 800),
        snackBarSize: Size.zero,
        materialBannerSize: Size.zero,
        textDirection: TextDirection.rtl,
      );

      final rtlOffset = location.getOffset(rtlGeometry);
      expect(rtlOffset.dx, equals(24));
      // 800 - 56 - 48 (safe area) - 20
      expect(rtlOffset.dy, equals(800 - 56 - 48 - 20));

      // With 80dp bottom navigation bar (800 - 80 - 300 keyboard = 420)
      const navBarGeometry = ScaffoldPrelayoutGeometry(
        bottomSheetSize: Size.zero,
        contentBottom: 420,
        contentTop: 80,
        floatingActionButtonSize: Size(56, 56),
        minInsets: EdgeInsets.only(bottom: 300),
        minViewPadding: EdgeInsets.only(bottom: 48),
        scaffoldSize: Size(400, 800),
        snackBarSize: Size.zero,
        materialBannerSize: Size.zero,
        textDirection: TextDirection.ltr,
      );

      final navBarOffset = location.getOffset(navBarGeometry);
      // 800 - 56 - 80 (nav bar) - 20
      expect(navBarOffset.dy, equals(800 - 56 - 80 - 20));

      // With respectSafeArea: false
      const rawLocation = AppStationaryEndFloatFabLocation(
        bottomOffset: 20,
        endOffset: 24,
        respectSafeArea: false,
      );
      final rawOffset = rawLocation.getOffset(ltrGeometry);
      expect(rawOffset.dy, equals(800 - 56 - 20));
    });
  });
}
