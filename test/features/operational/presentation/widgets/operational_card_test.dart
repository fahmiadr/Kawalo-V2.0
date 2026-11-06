import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/presentation/widgets/operational_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleWorkerWithoutPic = OperationalItemEntity(
    id: 'agus@kawalo.id_2026-09-22',
    userEmail: 'agus@kawalo.id',
    userName: 'Agus Pratama',
    latestDuty: 'ON DUTY',
    latestState: 'Patroli Aktif',
    latestDutyDt: '2026-09-22T08:00:00Z',
    totalActivities: 5,
    timeline: <DutyTimelineEntity>[],
  );

  const sampleWorkerWithPic = OperationalItemEntity(
    id: 'agus@kawalo.id_2026-09-22',
    userEmail: 'agus@kawalo.id',
    userName: 'Agus Pratama',
    userProfilePic: 'https://example.com/avatar.jpg',
    latestDuty: 'ON DUTY',
    latestState: 'Patroli Aktif',
    latestDutyDt: '2026-09-22T08:00:00Z',
    totalActivities: 5,
    timeline: <DutyTimelineEntity>[],
  );

  Widget buildTestWidget(OperationalItemEntity item) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: Scaffold(
        body: OperationalCard(item: item),
      ),
    );
  }

  group('OperationalCard Tests', () {
    testWidgets('renders fallback vector avatar when userProfilePic is null',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(sampleWorkerWithoutPic));
      await tester.pumpAndSettle();

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.text('Agus Pratama'), findsOneWidget);
      expect(find.text('agus@kawalo.id'), findsOneWidget);
      expect(find.byType(AppSvgIcon), findsWidgets);
    });

    testWidgets('handles network photo URL gracefully', (tester) async {
      await tester.pumpWidget(buildTestWidget(sampleWorkerWithPic));
      await tester.pump();

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.text('Agus Pratama'), findsOneWidget);
      expect(find.text('agus@kawalo.id'), findsOneWidget);
    });
  });
}
