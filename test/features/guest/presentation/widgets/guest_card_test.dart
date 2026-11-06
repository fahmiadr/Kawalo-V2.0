import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_selection.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_card.dart';

void main() {
  const sampleExitedGuest = GuestItemEntity(
    id: '1',
    guestName: 'Bambang Sudarsono',
    guestNumber: 'B 2706 SBX',
    guestCategory: 'Taxi • KTP',
    guestDestination: 'JKN Veranda',
    guestToUserName: 'Wisnu Wijayadi - Veranda',
    guestPurpose: 'Jemput Mrs. Carine',
    groupName: 'JKN Veranda',
    guestIdentity: 'CT 10713',
    guestIdentityType: 'KTP',
    guestType: 'Visitor',
    guestDt: '08 Jul 2026 14:00',
    guestAckDt: '08 Jul 2026 14:05',
    guestOutDt: '08 Jul 2026 15:21',
  );

  const sampleWaitingGuest = GuestItemEntity(
    id: '2',
    guestName: 'Reni Marsiti',
    guestNumber: 'D 1892 KLP',
    guestCategory: 'Taxi • OTHER',
    guestDestination: 'Cluster Flamboyan',
    guestToUserName: 'Wisnu Wijayadi - Veranda',
    guestPurpose: 'Jemput Anna Depalma',
    groupName: 'Cluster Flamboyan',
    guestIdentity: 'CT 10822',
    guestIdentityType: 'SIM',
    guestType: 'Visitor',
    guestDt: '08 Jul 2026 14:01',
  );

  Widget buildCardWidget(
    GuestItemEntity item, {
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool isSelectionMode = false,
    bool isSelected = false,
    bool isSelectable = true,
  }) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GuestCard(
              item: item,
              onTap: onTap,
              onLongPress: onLongPress,
              isSelectionMode: isSelectionMode,
              isSelected: isSelected,
              isSelectable: isSelectable,
            ),
          ),
        ),
      ),
    );
  }

  group('GuestCard Widget Tests', () {
    testWidgets('renders all card details with exited status (Keluar)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildCardWidget(sampleExitedGuest));
      await tester.pumpAndSettle();

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.byType(AppDivider), findsOneWidget);
      expect(find.byType(AppTag), findsNWidgets(2));
      expect(find.text('Bambang Sudarsono'), findsOneWidget);
      expect(find.text('Visitor • KTP'), findsOneWidget);
      expect(find.text('Taxi • KTP'), findsOneWidget); // category tag
      expect(find.text('JKN Veranda'), findsOneWidget); // destination
      expect(find.text('Jemput Mrs. Carine'), findsOneWidget);
      expect(find.text('Status terakhir: 08 Jul 2026 15:21'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);
    });

    testWidgets('renders all card details with waiting status (Masuk)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildCardWidget(sampleWaitingGuest));
      await tester.pumpAndSettle();

      expect(find.byType(AppTag), findsNWidgets(2));
      expect(find.text('Reni Marsiti'), findsOneWidget);
      expect(find.text('Visitor • SIM'), findsOneWidget);
      expect(find.text('Taxi • OTHER'), findsOneWidget); // category tag
      expect(find.text('Cluster Flamboyan'), findsOneWidget); // destination
      expect(find.text('Jemput Anna Depalma'), findsOneWidget);
      expect(find.text('Status terakhir: 08 Jul 2026 14:01'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when card is tapped',
        (WidgetTester tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildCardWidget(
          sampleExitedGuest,
          onTap: () => tapped = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('passes accessible semantic label to AppCard',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildCardWidget(sampleExitedGuest));
      await tester.pumpAndSettle();

      final card = tester.widget<AppCard>(find.byType(AppCard));
      expect(
        card.semanticLabel,
        contains('Data tamu Bambang Sudarsono'),
      );
      expect(
        card.semanticLabel,
        contains('status terakhir Keluar'),
      );
    });

    testWidgets(
        'renders safely under 200% dynamic text scaling without overflow',
        (WidgetTester tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(buildCardWidget(sampleExitedGuest));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Bambang Sudarsono'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);
    });

    testWidgets('triggers onLongPress callback when card is long-pressed',
        (WidgetTester tester) async {
      var longPressed = false;
      await tester.pumpWidget(
        buildCardWidget(
          sampleExitedGuest,
          onLongPress: () => longPressed = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(AppCard));
      await tester.pumpAndSettle();

      expect(longPressed, isTrue);
    });

    testWidgets(
      'renders AppSelectionLeading with check icon when isSelectionMode and '
      'isSelected are true',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildCardWidget(
            sampleExitedGuest,
            isSelectionMode: true,
            isSelected: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppSelectionLeading), findsOneWidget);
        final card = tester.widget<AppCard>(find.byType(AppCard));
        expect(card.semanticLabel, contains('terpilih'));
      },
    );

    testWidgets(
      'renders opacity 0.38 and lock icon when isSelectionMode is true and '
      'isSelectable is false',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildCardWidget(
            sampleExitedGuest,
            isSelectionMode: true,
            isSelectable: false,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppSelectionLeading), findsNothing);
        final opacityFinder = find.byType(Opacity);
        expect(opacityFinder, findsOneWidget);
        final opacity = tester.widget<Opacity>(opacityFinder);
        expect(opacity.opacity, AppStateLayer.disabledOpacity);
      },
    );
  });
}
