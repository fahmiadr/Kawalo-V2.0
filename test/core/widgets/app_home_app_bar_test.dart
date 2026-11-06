import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_search.dart';
import 'package:kawalo_mobile/core/widgets/kawalo_logo.dart';

void main() {
  Widget buildTestApp(Widget appBar) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: Scaffold(
        appBar: appBar as PreferredSizeWidget,
        body: const Center(child: Text('Content')),
      ),
    );
  }

  group('AppHomeAppBar Tests', () {
    testWidgets('renders greeting, logo, and notification button',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppHomeAppBar(
            greeting: 'Selamat siang, admin AHMAD ZAKI FAUZAN!',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Selamat siang, admin AHMAD ZAKI FAUZAN!'),
        findsOneWidget,
      );
      expect(find.byType(KawaloLogoText), findsOneWidget);
      expect(find.byType(AppHomeAppBar), findsOneWidget);
      expect(find.byType(AppIconButton), findsOneWidget);
      expect(find.text('9'), findsNothing);
    });

    testWidgets('renders badge with count when unreadNotificationsCount > 0',
        (tester) async {
      var notificationTapped = false;

      await tester.pumpWidget(
        buildTestApp(
          AppHomeAppBar(
            greeting: 'Selamat siang, admin!',
            unreadNotificationsCount: 9,
            onNotificationPressed: () {
              notificationTapped = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('9'), findsOneWidget);
      expect(find.byType(AppIconButton), findsOneWidget);

      // Tapping on the badge itself should not be blocked and must trigger
      // the notification action.
      await tester.tap(find.text('9'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(notificationTapped, isTrue);
    });

    testWidgets('renders 99+ when unreadNotificationsCount exceeds 99',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppHomeAppBar(
            greeting: 'Selamat pagi, admin!',
            unreadNotificationsCount: 150,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('respects custom leading and trailing widgets', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppHomeAppBar(
            greeting: 'Halo User',
            leading: Text('Custom Leading'),
            trailing: Text('Custom Trailing'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom Leading'), findsOneWidget);
      expect(find.text('Custom Trailing'), findsOneWidget);
      expect(find.byType(KawaloLogoText), findsNothing);
    });

    testWidgets('renders headline title text when title parameter is provided',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppHomeAppBar(
            greeting: 'Diperbarui Hari ini, 14.20',
            title: 'Pusat Informasi',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Diperbarui Hari ini, 14.20'), findsOneWidget);
      expect(find.text('Pusat Informasi'), findsOneWidget);
      expect(find.byType(KawaloLogoText), findsNothing);
    });

    testWidgets(
      'renders safely under 200% dynamic text scaling without overflow',
      (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        buildTestApp(
          const AppHomeAppBar(
            greeting: 'Selamat siang, admin!',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(KawaloLogoText), findsOneWidget);

      final logoWidget =
          tester.widget<KawaloLogoText>(find.byType(KawaloLogoText));
      expect(logoWidget.textScaler, equals(TextScaler.noScaling));
    });

    testWidgets('renders back button and handles onBackPressed',
        (WidgetTester tester) async {
      var backTapped = false;

      await tester.pumpWidget(
        buildTestApp(
          AppHomeAppBar(
            greeting: 'Diperbarui Hari ini, 15.20',
            title: 'Data Tamu',
            showBackButton: true,
            onBackPressed: () {
              backTapped = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Data Tamu'), findsOneWidget);
      expect(find.bySemanticsLabel('Kembali'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Kembali'));
      await tester.pumpAndSettle();

      expect(backTapped, isTrue);
    });

    testWidgets('renders searchBar and increases preferredSize height',
        (WidgetTester tester) async {
      const appBarWithSearch = AppHomeAppBar(
        greeting: 'Diperbarui Hari ini, 15.20',
        title: 'Data Tamu',
        searchBar: Text('Search Placeholder'),
      );

      expect(
        appBarWithSearch.preferredSize.height,
        equals(
          AppHomeAppBar.defaultPreferredHeight +
              AppHomeAppBar.defaultSearchBarHeight,
        ),
      );

      await tester.pumpWidget(buildTestApp(appBarWithSearch));
      await tester.pumpAndSettle();

      expect(find.text('Search Placeholder'), findsOneWidget);
      expect(find.text('Data Tamu'), findsOneWidget);
    });

    testWidgets(
        'back button and trailing button provide unblocked 48x48 touch targets '
        'and respond to boundary taps', (WidgetTester tester) async {
      var backTaps = 0;
      var notificationTaps = 0;

      await tester.pumpWidget(
        buildTestApp(
          AppHomeAppBar(
            greeting: 'Diperbarui Hari ini, 15.20',
            title: 'Data Tamu',
            showBackButton: true,
            onBackPressed: () => backTaps++,
            unreadNotificationsCount: 1,
            onNotificationPressed: () => notificationTaps++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final backFinder = find.bySemanticsLabel('Kembali');
      final backSize = tester.getSize(backFinder);
      expect(backSize.width, greaterThanOrEqualTo(48.0));
      expect(backSize.height, greaterThanOrEqualTo(48.0));

      final backCenter = tester.getCenter(backFinder);

      // Tap near top (within touch target).
      await tester.tapAt(backCenter - const Offset(0, 16));
      await tester.pumpAndSettle();
      expect(backTaps, equals(1));

      // Tap near bottom (within touch target).
      await tester.tapAt(backCenter + const Offset(0, 16));
      await tester.pumpAndSettle();
      expect(backTaps, equals(2));

      // Tap near left (within touch target).
      await tester.tapAt(backCenter - const Offset(16, 0));
      await tester.pumpAndSettle();
      expect(backTaps, equals(3));

      // Tap near right (within touch target).
      await tester.tapAt(backCenter + const Offset(16, 0));
      await tester.pumpAndSettle();
      expect(backTaps, equals(4));

      final notifFinder = find.byType(AppIconButton).first;
      final notifSize = tester.getSize(notifFinder);
      expect(notifSize.width, greaterThanOrEqualTo(48.0));
      expect(notifSize.height, greaterThanOrEqualTo(48.0));

      final notifCenter = tester.getCenter(notifFinder);

      // Tap near top of notification button.
      await tester.tapAt(notifCenter - const Offset(0, 16));
      await tester.pumpAndSettle();
      expect(notificationTaps, equals(1));

      // Tap near bottom of notification button.
      await tester.tapAt(notifCenter + const Offset(0, 16));
      await tester.pumpAndSettle();
      expect(notificationTaps, equals(2));

      // Tap near left of notification button.
      await tester.tapAt(notifCenter - const Offset(16, 0));
      await tester.pumpAndSettle();
      expect(notificationTaps, equals(3));

      // Tap near right of notification button.
      await tester.tapAt(notifCenter + const Offset(16, 0));
      await tester.pumpAndSettle();
      expect(notificationTaps, equals(4));
    });

    testWidgets(
        'renders title with back button without greeting and without trailing',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppHomeAppBar(
            title: 'Detail tamu',
            showBackButton: true,
            showTrailing: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detail tamu'), findsOneWidget);
      expect(find.bySemanticsLabel('Kembali'), findsOneWidget);
      // Only 1 AppIconButton (the back button), no trailing notification button
      expect(find.byType(AppIconButton), findsOneWidget);
      expect(find.byType(KawaloLogoText), findsNothing);
    });

    testWidgets('tapping back button triggers onBackPressed callback',
        (tester) async {
      var backTapped = false;
      await tester.pumpWidget(
        buildTestApp(
          AppHomeAppBar(
            title: 'Detail tamu',
            showBackButton: true,
            showTrailing: false,
            onBackPressed: () {
              backTapped = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Kembali'));
      await tester.pumpAndSettle();

      expect(backTapped, isTrue);
    });

    testWidgets(
        'trailing button sizes (md, lg) are unconstrained and render at their '
        'proper sizes', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppHomeAppBar(
            title: 'Test Trailing Sizing',
            trailing: AppIconButton(
              key: ValueKey('trailing_btn_md'),
              icon: Icon(Icons.download),
              size: AppIconButtonSize.md,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final mdSize =
          tester.getSize(find.byKey(const ValueKey('trailing_btn_md')));
      expect(mdSize.width, equals(56.0));
      expect(mdSize.height, equals(56.0));

      await tester.pumpWidget(
        buildTestApp(
          const AppHomeAppBar(
            title: 'Test Trailing Sizing',
            trailing: AppIconButton(
              key: ValueKey('trailing_btn_lg'),
              icon: Icon(Icons.download),
              size: AppIconButtonSize.lg,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final lgSize =
          tester.getSize(find.byKey(const ValueKey('trailing_btn_lg')));
      expect(lgSize.width, greaterThan(48.0));
      expect(lgSize.height, greaterThan(48.0));
    });

    testWidgets(
        'back button respects backButtonSize and renders without container '
        'clamping', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppHomeAppBar(
            title: 'Test Back Button Sizing',
            showBackButton: true,
            backButtonSize: AppIconButtonSize.lg,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final backFinder = find.bySemanticsLabel('Kembali');
      final backSize = tester.getSize(backFinder);
      expect(backSize.width, greaterThan(48.0));
      expect(backSize.height, greaterThan(48.0));
    });

    testWidgets(
        'leading button precedes title when both leading and title are '
        'provided', (tester) async {
      var leadingTapped = false;
      await tester.pumpWidget(
        buildTestApp(
          AppHomeAppBar(
            title: 'Data Tamu',
            leading: AppIconButton(
              key: const ValueKey('custom_leading_btn'),
              icon: const Icon(Icons.close),
              size: AppIconButtonSize.md,
              onPressed: () => leadingTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('custom_leading_btn')), findsOneWidget);
      expect(find.text('Data Tamu'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('custom_leading_btn')));
      await tester.pumpAndSettle();

      expect(leadingTapped, isTrue);
    });

    testWidgets(
        'reserveGreetingSpace locks title vertically and prevents layout shift '
        'when greeting loads', (tester) async {
      // Step 1: Render with reserveGreetingSpace: true
      // and greetingLoading: true
      await tester.pumpWidget(
        buildTestApp(
          const AppHomeAppBar(
            reserveGreetingSpace: true,
            greetingLoading: true,
            title: 'Pusat Informasi',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Pusat Informasi'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Memuat status pembaruan data'),
        findsOneWidget,
      );
      final initialTitleOffset =
          tester.getTopLeft(find.text('Pusat Informasi'));

      // Step 2: Render with valid greeting loaded
      await tester.pumpWidget(
        buildTestApp(
          const AppHomeAppBar(
            reserveGreetingSpace: true,
            greeting: 'Diperbarui Hari ini, 15.20',
            title: 'Pusat Informasi',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Diperbarui Hari ini, 15.20'), findsOneWidget);
      expect(find.text('Pusat Informasi'), findsOneWidget);
      final finalTitleOffset = tester.getTopLeft(find.text('Pusat Informasi'));

      // The vertical Y-position of the title MUST remain exactly identical!
      expect(finalTitleOffset.dy, equals(initialTitleOffset.dy));
    });

    testWidgets('renders titleWidget when provided instead of text title',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppHomeAppBar(
            titleWidget: KeyedSubtree(
              key: ValueKey('custom_search_bar'),
              child: Text('Inline Search'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('custom_search_bar')), findsOneWidget);
      expect(find.text('Inline Search'), findsOneWidget);
      expect(find.byType(KawaloLogoText), findsNothing);
    });

    testWidgets(
        'title and titleWidget search bar start at exact same horizontal '
        'alignment without extra padding', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppHomeAppBar(
            greeting: 'Data tamu',
            reserveGreetingSpace: true,
            title: 'Data tamu',
            showBackButton: true,
            trailing: AppIconButton(
              icon: Icon(Icons.search),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final backBtnFinder = find.bySemanticsLabel('Kembali');
      final backBox = tester.renderObject(backBtnFinder) as RenderBox;
      final backRect = backBox.localToGlobal(Offset.zero) & backBox.size;

      final titleFinder = find.text('Data tamu').last;
      final titleBox = tester.renderObject(titleFinder) as RenderBox;
      final titleRect = titleBox.localToGlobal(Offset.zero) & titleBox.size;

      expect(titleRect.left - backRect.right, equals(8));

      await tester.pumpWidget(
        buildTestApp(
          const AppHomeAppBar(
            greeting: 'Data tamu',
            reserveGreetingSpace: true,
            titleWidget: AppSearchBar(
              hintText: 'Cari data tamu',
              constraints: BoxConstraints(minHeight: 40, maxHeight: 40),
            ),
            showBackButton: true,
            trailing: AppIconButton(
              icon: Icon(Icons.close),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final searchFinder = find.byType(AppSearchBar);
      final searchBox = tester.renderObject(searchFinder) as RenderBox;
      final searchRect = searchBox.localToGlobal(Offset.zero) & searchBox.size;

      expect(searchRect.left, equals(titleRect.left));
      expect(searchRect.left - backRect.right, equals(8));
    });
  });
}
