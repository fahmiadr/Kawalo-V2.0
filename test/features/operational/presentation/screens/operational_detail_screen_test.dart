import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_fab.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/presentation/cubit/operational_cubit.dart';
import 'package:kawalo_mobile/features/operational/presentation/cubit/operational_state.dart';
import 'package:kawalo_mobile/features/operational/presentation/screens/operational_detail_screen.dart';
import 'package:kawalo_mobile/features/operational/presentation/widgets/operational_detail_top_meta.dart';
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
    latestDutyDt: '2026-07-08T10:00:00Z',
    totalActivities: 5,
    timeline: [
      DutyTimelineEntity(
        id: '1',
        journeyUid: 'journey-001',
        duty: 'Patroli Lingkungan',
        state: 'Aktif',
        dutyDt: '2026-07-08T10:00:00Z',
      ),
      DutyTimelineEntity(
        id: '2',
        journeyUid: 'journey-002',
        duty: 'Pemeriksaan Pos',
        state: 'Selesai',
        dutyDt: '2026-07-08T09:00:00Z',
      ),
    ],
  );

  Widget buildDetailWidget({
    required OperationalItemEntity item,
    Future<void> Function()? onRefresh,
  }) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: OperationalDetailScreen(
        item: item,
        onRefresh: onRefresh,
      ),
    );
  }

  group('OperationalDetailScreen Widget Tests', () {
    testWidgets('renders AppHomeAppBar, top meta, profile card, and timeline',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildDetailWidget(item: sampleWorker));
      await tester.pumpAndSettle();

      expect(find.byType(AppHomeAppBar), findsOneWidget);
      expect(find.text('Detail operasional'), findsOneWidget);

      // Top meta
      expect(find.byType(OperationalDetailTopMeta), findsOneWidget);
      expect(find.text('Tim Bravo Patroli'), findsOneWidget);

      // Profile card
      expect(find.text('Agus Pratama'), findsOneWidget);
      expect(find.text('agus@kawalo.id'), findsOneWidget);

      // Summary card
      expect(find.text('Ringkasan dinas harian'), findsOneWidget);

      // Timeline card
      expect(find.text('Riwayat aktivitas dinas'), findsOneWidget);
      expect(find.text('Pemeriksaan Pos'), findsOneWidget);

      // No SOS FAB
      expect(find.byType(AppExtendedFab), findsNothing);
      expect(find.text('SOS'), findsNothing);
      expect(find.byType(AppCard), findsNWidgets(3));
    });

    testWidgets('pull-to-refresh on OperationalDetailScreen triggers callback',
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
        find.text('Agus Pratama'),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(refreshed, isTrue);
    });

    testWidgets('displays lastSync greeting when cubit is provided',
        (WidgetTester tester) async {
      final mockCubit = MockOperationalCubit();
      when(() => mockCubit.state).thenReturn(
        const OperationalLoaded(
          operationals: [sampleWorker],
          lastSync: 'Diperbarui Kemarin, 14.20',
        ),
      );
      when(() => mockCubit.stream)
          .thenAnswer((_) => const Stream<OperationalState>.empty());
      when(() => mockCubit.currentGreeting).thenReturn('Selamat Siang');

      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: OperationalDetailScreen(
            item: sampleWorker,
            cubit: mockCubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Diperbarui Kemarin, 14.20'), findsOneWidget);
    });

    testWidgets('renders AppBottomOfflineBanner when offline',
        (WidgetTester tester) async {
      final offlineConnectivityCubit = ConnectivityCubit(
        initialState: ConnectivityStatus.offline,
        autoStart: false,
      );

      await tester.pumpWidget(
        BlocProvider<ConnectivityCubit>.value(
          value: offlineConnectivityCubit,
          child: M3EMaterialApp(
            data: AppTheme.m3eLight(),
            home: const OperationalDetailScreen(
              item: sampleWorker,
            ),
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

    testWidgets('hides AppBottomOfflineBanner when online',
        (WidgetTester tester) async {
      final onlineConnectivityCubit = ConnectivityCubit(
        autoStart: false,
      );

      await tester.pumpWidget(
        BlocProvider<ConnectivityCubit>.value(
          value: onlineConnectivityCubit,
          child: M3EMaterialApp(
            data: AppTheme.m3eLight(),
            home: const OperationalDetailScreen(
              item: sampleWorker,
            ),
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
