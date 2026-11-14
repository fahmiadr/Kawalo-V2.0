import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/presentation/cubit/operational_cubit.dart';
import 'package:kawalo_mobile/features/operational/presentation/cubit/operational_state.dart';
import 'package:kawalo_mobile/features/operational/presentation/screens/operational_detail_screen.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleWorker = OperationalItemEntity(
    id: 'agus@kawalo.id_2026-07-08',
    userEmail: 'agus@kawalo.id',
    userName: 'Agus Pratama',
    groupName: 'Tim Bravo Patroli',
    latestDuty: 'Patroli Lingkungan',
    latestState: 'Aktif',
    latestDutyDt: '2026-07-08T10:00:00',
    dutyDate: '2026-07-08',
    totalActivities: 5,
    timeline: [
      DutyTimelineEntity(
        id: '1',
        journeyUid: 'journey-001',
        duty: 'Patroli Lingkungan',
        state: 'Aktif',
        dutyDt: '2026-07-08T10:00:00',
      ),
      DutyTimelineEntity(
        id: '2',
        journeyUid: 'journey-002',
        duty: 'Pemeriksaan Pos',
        state: 'Selesai',
        dutyDt: '2026-07-08T09:00:00',
      ),
    ],
  );

  Widget buildDetailWidget({
    required OperationalItemEntity item,
    Future<void> Function()? onRefresh,
  }) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      localizationsDelegates: AppTheme.localizationsDelegates,
      home: OperationalDetailScreen(
        item: item,
        onRefresh: onRefresh,
        clock: () => DateTime(2026, 7, 8, 12),
      ),
    );
  }

  group('OperationalDetailScreen Widget Tests', () {
    testWidgets("shows the name, summary and today's history", (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildDetailWidget(item: sampleWorker));
      await tester.pumpAndSettle();

      expect(find.text('Agus Pratama'), findsOneWidget);
      expect(find.text('Mulai dinas'), findsOneWidget);
      expect(find.text('09.00'), findsNWidgets(2));
      expect(find.text('Aktif · 10.00'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('RIWAYAT HARI INI'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('Pemeriksaan Pos'), findsOneWidget);
      expect(find.text('10.00'), findsOneWidget);
    });

    testWidgets('another day is labelled as activity history', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          localizationsDelegates: AppTheme.localizationsDelegates,
          home: OperationalDetailScreen(
            item: sampleWorker,
            clock: () => DateTime(2026, 7, 9),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RIWAYAT AKTIVITAS'), findsOneWidget);
      expect(find.text('8 Jul 10.00'), findsOneWidget);
    });

    testWidgets(
      'pull-to-refresh on OperationalDetailScreen triggers callback',
      (WidgetTester tester) async {
        var refreshed = false;

        await tester.pumpWidget(
          buildDetailWidget(
            item: sampleWorker,
            onRefresh: () async {
              refreshed = true;
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.fling(
          find.text('Mulai dinas'),
          const Offset(0, 300),
          1000,
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        expect(refreshed, isTrue);
      },
    );

    testWidgets('follows the refreshed item from the cubit', (
      WidgetTester tester,
    ) async {
      final mockCubit = MockOperationalCubit();
      const refreshed = OperationalItemEntity(
        id: 'agus@kawalo.id_2026-07-08',
        userEmail: 'agus@kawalo.id',
        userName: 'Agus Pratama',
        latestDuty: 'OFF DUTY',
        latestState: 'Pulang',
        latestDutyDt: '2026-07-08T15:00:00',
        dutyDate: '2026-07-08',
        totalActivities: 6,
        timeline: [],
      );
      when(() => mockCubit.state).thenReturn(
        const OperationalLoaded(operationals: [refreshed], lastSync: ''),
      );
      when(
        () => mockCubit.stream,
      ).thenAnswer((_) => const Stream<OperationalState>.empty());

      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          localizationsDelegates: AppTheme.localizationsDelegates,
          home: OperationalDetailScreen(item: sampleWorker, cubit: mockCubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OFF DUTY'), findsOneWidget);
      expect(find.text('Belum ada riwayat aktivitas dinas.'), findsOneWidget);
    });

    testWidgets('renders AppBottomOfflineBanner when offline', (
      WidgetTester tester,
    ) async {
      final offlineConnectivityCubit = ConnectivityCubit(
        initialState: ConnectivityStatus.offline,
        autoStart: false,
      );

      await tester.pumpWidget(
        BlocProvider<ConnectivityCubit>.value(
          value: offlineConnectivityCubit,
          child: M3EMaterialApp(
            data: AppTheme.m3eLight(),
            localizationsDelegates: AppTheme.localizationsDelegates,
            home: const OperationalDetailScreen(item: sampleWorker),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBottomOfflineBanner), findsOneWidget);
      expect(
        find.text('Mode offline — Menampilkan data tersimpan'),
        findsOneWidget,
      );
    });

    testWidgets('hides AppBottomOfflineBanner when online', (
      WidgetTester tester,
    ) async {
      final onlineConnectivityCubit = ConnectivityCubit(autoStart: false);

      await tester.pumpWidget(
        BlocProvider<ConnectivityCubit>.value(
          value: onlineConnectivityCubit,
          child: M3EMaterialApp(
            data: AppTheme.m3eLight(),
            localizationsDelegates: AppTheme.localizationsDelegates,
            home: const OperationalDetailScreen(item: sampleWorker),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Mode offline — Menampilkan data tersimpan'),
        findsNothing,
      );
      expect(find.text('Kembali online'), findsNothing);
      final banner = tester.widget<AppBottomOfflineBanner>(
        find.byType(AppBottomOfflineBanner),
      );
      expect(banner.isOffline, isFalse);
    });
  });
}

class MockOperationalCubit extends Mock implements OperationalCubit {}
