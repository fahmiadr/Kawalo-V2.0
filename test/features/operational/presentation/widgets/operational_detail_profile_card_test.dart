import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/presentation/widgets/operational_detail_profile_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleWorkerOnDuty = OperationalItemEntity(
    id: 'budi@kawalo.id_2026-07-08',
    userEmail: 'budi@kawalo.id',
    userName: 'Budi Santoso',
    groupName: 'Tim Alpha Jaga',
    latestDuty: 'ON DUTY',
    latestState: 'Patroli Gerbang Utama',
    latestDutyDt: '2026-07-08T10:15:00Z',
    totalActivities: 8,
    timeline: <DutyTimelineEntity>[],
  );

  const sampleWorkerWithPic = OperationalItemEntity(
    id: 'citra@kawalo.id_2026-07-08',
    userEmail: 'citra@kawalo.id',
    userName: 'Citra Kirana',
    userProfilePic: 'https://example.com/citra.jpg',
    groupName: 'Tim Beta',
    latestDuty: 'OFF DUTY',
    latestState: 'Istirahat',
    latestDutyDt: '2026-07-08T18:00:00Z',
    totalActivities: 4,
    timeline: <DutyTimelineEntity>[],
  );

  Widget buildTestWidget(OperationalItemEntity item) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: Scaffold(
        body: OperationalDetailProfileCard(item: item),
      ),
    );
  }

  group('OperationalDetailProfileCard Tests', () {
    testWidgets('renders basic profile info, tags, and fallback vector avatar',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(sampleWorkerOnDuty));
      await tester.pumpAndSettle();

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('budi@kawalo.id'), findsOneWidget);
      expect(find.text('ON DUTY'), findsOneWidget);

      // Verify on-duty uses primary tag variant
      final tags = tester.widgetList<AppTag>(find.byType(AppTag)).toList();
      final dutyTag = tags.firstWhere((tag) => tag.label == 'ON DUTY');
      expect(dutyTag.variant, AppTagVariant.primary);
    });

    testWidgets('renders off-duty tag variant tertiary and handles photo URL',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(sampleWorkerWithPic));
      await tester.pump();

      expect(find.text('Citra Kirana'), findsOneWidget);
      expect(find.text('citra@kawalo.id'), findsOneWidget);
      expect(find.text('OFF DUTY'), findsOneWidget);

      final tags = tester.widgetList<AppTag>(find.byType(AppTag)).toList();
      final dutyTag = tags.firstWhere((tag) => tag.label == 'OFF DUTY');
      expect(dutyTag.variant, AppTagVariant.tertiary);
    });
  });
}
