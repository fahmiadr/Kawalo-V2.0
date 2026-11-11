import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/app_shortcut_card.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: Scaffold(
        body: Center(child: SizedBox(width: 180, height: 120, child: child)),
      ),
    );
  }

  group('AppShortcutCard Tests', () {
    testWidgets('renders shortcut card with title, subtitle, and badge', (
      tester,
    ) async {
      var tapped = false;

      final item = AppShortcutItem(
        title: 'Insiden',
        subtitle: 'Laporan Kejadian',
        badgeText: 'BARU!',
        iconPath: KawaloColorVectors.incident1,
        onTap: () => tapped = true,
      );

      await tester.pumpWidget(buildTestWidget(AppShortcutCard(item: item)));
      await tester.pumpAndSettle();

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.text('Insiden'), findsOneWidget);
      expect(find.text('Laporan Kejadian'), findsOneWidget);
      expect(find.text('BARU!'), findsOneWidget);

      await tester.tap(find.text('Insiden'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('renders shortcut card without subtitle', (tester) async {
      const item = AppShortcutItem(
        title: 'Data Tamu',
        iconPath: KawaloColorVectors.guestValidation,
      );

      await tester.pumpWidget(
        buildTestWidget(const AppShortcutCard(item: item)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Data Tamu'), findsOneWidget);
    });

    testWidgets('renders compact AppShortcutCard correctly', (tester) async {
      const item = AppShortcutItem(
        title: 'Aktifitas Operasional',
        iconPath: KawaloColorVectors.patrol2,
      );

      await tester.pumpWidget(
        buildTestWidget(
          const AppShortcutCard(item: item, size: AppShortcutCardSize.compact),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.text('Aktifitas Operasional'), findsOneWidget);

      final cardWidget = tester.widget<AppShortcutCard>(
        find.byType(AppShortcutCard),
      );
      expect(cardWidget.isCompact, isTrue);
    });
  });
}
