import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/presentation/widgets/operational_detail_summary_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleWorkerWithTimeline = OperationalItemEntity(
    id: 'dani@kawalo.id_2026-07-08',
    userEmail: 'dani@kawalo.id',
    userName: 'Dani Ramadhan',
    groupName: 'Tim Bravo',
    latestDuty: 'ON DUTY',
    latestState: 'Patroli Sektor Barat',
    latestDutyDt: '2026-07-08T15:30:00Z',
    totalActivities: 3,
    timeline: [
      DutyTimelineEntity(
        id: '3',
        journeyUid: 'journey-3',
        duty: 'ON DUTY',
        state: 'Patroli Sektor Barat',
        dutyDt: '2026-07-08T15:30:00Z',
      ),
      DutyTimelineEntity(
        id: '2',
        journeyUid: 'journey-2',
        duty: 'ON DUTY',
        state: 'Standby Pos 1',
        dutyDt: '2026-07-08T11:00:00Z',
      ),
      DutyTimelineEntity(
        id: '1',
        journeyUid: 'journey-1',
        duty: 'ON DUTY',
        state: 'Absen Masuk',
        dutyDt: '2026-07-08T07:00:00Z',
      ),
    ],
  );

  const sampleWorkerEmptyTimeline = OperationalItemEntity(
    id: 'eko@kawalo.id_2026-07-08',
    userEmail: 'eko@kawalo.id',
    userName: 'Eko Prasetyo',
    groupName: 'Tim Charlie',
    latestDuty: 'ON DUTY',
    latestState: 'Apel Pagi',
    latestDutyDt: '2026-07-08T06:30:00Z',
    totalActivities: 1,
    timeline: <DutyTimelineEntity>[],
  );

  Widget buildTestWidget(OperationalItemEntity item) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: Scaffold(body: OperationalDetailSummaryCard(item: item)),
    );
  }

  group('OperationalDetailSummaryCard Tests', () {
    testWidgets('renders start of duty and latest update with timeline data', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(sampleWorkerWithTimeline));
      await tester.pumpAndSettle();

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.text('Ringkasan dinas harian'), findsOneWidget);
      expect(find.text('Mulai dinas'), findsOneWidget);
      expect(find.text('Status terkini'), findsOneWidget);

      // Verify status values
      expect(find.text('Absen Masuk'), findsOneWidget);
      expect(find.text('Patroli Sektor Barat'), findsOneWidget);
    });

    testWidgets('renders fallback status when timeline is empty', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(sampleWorkerEmptyTimeline));
      await tester.pumpAndSettle();

      expect(find.text('Ringkasan dinas harian'), findsOneWidget);
      expect(find.text('Apel Pagi'), findsNWidgets(2));
    });
  });
}
