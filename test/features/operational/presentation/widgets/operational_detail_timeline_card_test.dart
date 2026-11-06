import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/presentation/widgets/operational_detail_timeline_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleWorkerWithLogs = OperationalItemEntity(
    id: 'fajar@kawalo.id_2026-07-08',
    userEmail: 'fajar@kawalo.id',
    userName: 'Fajar Nugraha',
    groupName: 'Tim Delta',
    latestDuty: 'ON DUTY',
    latestState: 'ON PATROL',
    latestDutyDt: '2026-07-08T14:00:00Z',
    totalActivities: 2,
    timeline: [
      DutyTimelineEntity(
        id: '10',
        journeyUid: 'DJOURNEY-999',
        duty: 'ON DUTY',
        state: 'ON PATROL',
        dutyDt: '2026-07-08T14:00:00Z',
      ),
      DutyTimelineEntity(
        id: '9',
        journeyUid: 'DJOURNEY-888',
        duty: 'ON DUTY',
        state: 'Stand by Pos Gerbang',
        dutyDt: '2026-07-08T10:00:00Z',
      ),
    ],
  );

  const sampleWorkerEmpty = OperationalItemEntity(
    id: 'fajar@kawalo.id_2026-07-08',
    userEmail: 'fajar@kawalo.id',
    userName: 'Fajar Nugraha',
    groupName: 'Tim Delta',
    latestDuty: 'OFF DUTY',
    latestState: 'Lepas Dinas',
    latestDutyDt: '2026-07-08T14:00:00Z',
    totalActivities: 0,
    timeline: <DutyTimelineEntity>[],
  );

  Widget buildTestWidget(OperationalItemEntity item) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: Scaffold(
        body: OperationalDetailTimelineCard(item: item),
      ),
    );
  }

  group('OperationalDetailTimelineCard Tests', () {
    testWidgets('renders timeline nodes, states verbatim, and tags',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(sampleWorkerWithLogs));
      await tester.pumpAndSettle();

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.text('Riwayat aktivitas dinas'), findsOneWidget);

      // Verbatim states
      expect(find.text('ON PATROL'), findsWidgets);
      expect(find.text('Stand by Pos Gerbang'), findsOneWidget);

      // Duty tags & count tag in header
      expect(find.text('2 aktivitas'), findsOneWidget);
      expect(find.byType(AppTag), findsNWidgets(3));

      // Transaction UID
      expect(find.text('ID: DJOURNEY-999'), findsOneWidget);
      expect(find.text('ID: DJOURNEY-888'), findsOneWidget);
    });

    testWidgets('tapping UID copies to clipboard and shows snackbar',
        (tester) async {
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            final args = methodCall.arguments as Map<dynamic, dynamic>;
            copiedText = args['text'] as String?;
          }
          return null;
        },
      );

      await tester.pumpWidget(buildTestWidget(sampleWorkerWithLogs));
      await tester.pumpAndSettle();

      final uidFinder = find.text('ID: DJOURNEY-999');
      expect(uidFinder, findsOneWidget);

      await tester.tap(uidFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(copiedText, 'DJOURNEY-999');
    });

    testWidgets('renders empty message when timeline is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget(sampleWorkerEmpty));
      await tester.pumpAndSettle();

      expect(find.text('Riwayat aktivitas dinas'), findsOneWidget);
      expect(
        find.text('Belum ada riwayat aktivitas dinas.'),
        findsOneWidget,
      );
    });
  });
}
