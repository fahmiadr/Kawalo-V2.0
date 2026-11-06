import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_detail_app_bar.dart';

void main() {
  Widget buildTestApp({
    String greeting = 'Diperbarui Hari ini, 15.00',
    VoidCallback? onBackPressed,
    VoidCallback? onCheckout,
    bool isCheckingOut = false,
    bool enabled = true,
    Widget? trailing,
  }) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: Scaffold(
        appBar: GuestDetailAppBar(
          greeting: greeting,
          onBackPressed: onBackPressed,
          onCheckout: onCheckout,
          isCheckingOut: isCheckingOut,
          enabled: enabled,
          trailing: trailing,
        ),
      ),
    );
  }

  group('GuestDetailAppBar Tests', () {
    testWidgets('renders title, greeting, and back button without trailing',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Detail tamu'), findsOneWidget);
      expect(find.text('Diperbarui Hari ini, 15.00'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Kembali'),
        findsOneWidget,
      );
    });

    test('has correct preferredSize without search bar', () {
      const appBar = GuestDetailAppBar(
        greeting: 'Status',
      );

      expect(
        appBar.preferredSize.height,
        equals(AppHomeAppBar.defaultPreferredHeight),
      );
    });

    testWidgets('triggers onBackPressed when back button is tapped',
        (tester) async {
      var backTapped = false;

      await tester.pumpWidget(
        buildTestApp(
          onBackPressed: () => backTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Kembali'));
      await tester.pumpAndSettle();
      expect(backTapped, isTrue);
    });

    testWidgets('renders check-out button when onCheckout is provided',
        (tester) async {
      var checkoutTapped = false;

      await tester.pumpWidget(
        buildTestApp(
          onCheckout: () => checkoutTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Check-out'), findsOneWidget);
      expect(find.bySemanticsLabel('Check-out tamu'), findsOneWidget);

      await tester.tap(find.text('Check-out'));
      await tester.pumpAndSettle();
      expect(checkoutTapped, isTrue);
    });

    testWidgets(
        'disables check-out button when isCheckingOut or enabled is false',
        (tester) async {
      var checkoutTapped = false;

      await tester.pumpWidget(
        buildTestApp(
          onCheckout: () => checkoutTapped = true,
          isCheckingOut: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Check-out'));
      await tester.pumpAndSettle();
      expect(checkoutTapped, isFalse);
    });

    testWidgets('renders custom trailing widget when provided', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          trailing: const Text('Custom Trailing'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom Trailing'), findsOneWidget);
    });
  });
}
