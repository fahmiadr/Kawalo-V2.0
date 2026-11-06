import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/features/operational/presentation/widgets/operational_detail_app_bar.dart';

void main() {
  Widget buildTestApp({
    String greeting = 'Diperbarui Hari ini, 15.00',
    VoidCallback? onBackPressed,
  }) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: Scaffold(
        appBar: OperationalDetailAppBar(
          greeting: greeting,
          onBackPressed: onBackPressed,
        ),
      ),
    );
  }

  group('OperationalDetailAppBar Tests', () {
    testWidgets('renders title, greeting, and back button without trailing',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Detail operasional'), findsOneWidget);
      expect(find.text('Diperbarui Hari ini, 15.00'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Kembali'),
        findsOneWidget,
      );
    });

    test('has correct preferredSize without search bar', () {
      const appBar = OperationalDetailAppBar(
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
  });
}
