import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/presentation/widgets/operational_detail_top_meta.dart';

void main() {
  const sampleWorker = OperationalItemEntity(
    id: 'agus@kawalo.id_2026-07-08',
    userEmail: 'agus@kawalo.id',
    userName: 'Agus Pratama',
    groupName: 'Tim Bravo Patroli',
    latestDuty: 'Patroli Lingkungan',
    latestState: 'Aktif',
    latestDutyDt: '2026-07-08T10:00:00Z',
    totalActivities: 5,
    timeline: <DutyTimelineEntity>[],
  );

  Widget buildTestWidget(OperationalItemEntity item) {
    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: Scaffold(
        body: OperationalDetailTopMeta(item: item),
      ),
    );
  }

  group('OperationalDetailTopMeta Tests', () {
    testWidgets('renders AppTag with groupName and secondary variant',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(sampleWorker));
      await tester.pumpAndSettle();

      expect(find.byType(AppTag), findsOneWidget);
      expect(find.text('Tim Bravo Patroli'), findsOneWidget);

      final tag = tester.widget<AppTag>(find.byType(AppTag));
      expect(tag.variant, AppTagVariant.secondary);
      expect(tag.size, AppTagSize.medium);

      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, Alignment.centerLeft);
    });
  });
}
