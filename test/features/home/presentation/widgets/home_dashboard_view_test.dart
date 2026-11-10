import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_state.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_dashboard_view.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_management_section.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_quick_actions.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_recent_guests_card.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_shortcuts_section.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_screen_cubits.dart';

class MockIncidentListCubit extends MockCubit<IncidentState>
    implements IncidentListCubit {}

const _session = AuthSessionEntity(
  userId: 'usr_1',
  email: 'admin@kawalo.co.id',
  name: 'Admin',
  allowAdmin: true,
  allowPatrol: false,
  allowMonPatrol: false,
  groupUid: 'grp_1',
);

final Finder _staticBadgeInShortcuts = find.descendant(
  of: find.byType(HomeShortcutsSection),
  matching: find.text('BARU!'),
);

IncidentEntity _incident(String id, IncidentStatus status) => IncidentEntity(
  id: id,
  groupId: 'grp_1',
  title: 'Insiden $id',
  status: status,
  createdBy: 'usr_1',
  createdAt: DateTime(2026, 7),
);

void main() {
  Widget buildTestWidget({
    VoidCallback? onAbsensiPressed,
    VoidCallback? onCheckpointPressed,
    VoidCallback? onEditShortcutsPressed,
    VoidCallback? onEditManagementPressed,
  }) {
    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: Scaffold(
        body: HomeDashboardView(
          onAbsensiPressed: onAbsensiPressed,
          onCheckpointPressed: onCheckpointPressed,
          onEditShortcutsPressed: onEditShortcutsPressed,
          onEditManagementPressed: onEditManagementPressed,
        ),
      ),
    );
  }

  group('HomeDashboardView & Modular Home Widgets Tests', () {
    testWidgets('renders all major sections on dashboard', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Memastikan HomeRecentGuestsCard tampil
      expect(find.byType(HomeRecentGuestsCard), findsOneWidget);
      expect(find.text('Tamu Terakhir'), findsOneWidget);
      expect(find.text('Belum ada data tamu.'), findsOneWidget);

      // Memastikan HomeQuickActions tampil
      expect(find.byType(HomeQuickActions), findsOneWidget);
      expect(find.text('Absensi'), findsOneWidget);
      expect(find.text('Post to Post Checkpoint'), findsOneWidget);

      // Memastikan HomeShortcutsSection tampil
      expect(find.byType(HomeShortcutsSection), findsOneWidget);
      expect(find.text('Pintasan'), findsOneWidget);

      // Memastikan HomeManagementSection tampil
      expect(find.byType(HomeManagementSection), findsOneWidget);
      expect(find.text('Manajemen'), findsOneWidget);

      expect(find.text('Edit'), findsNWidgets(2));
      expect(find.byType(AppShortcutCard), findsWidgets);
    });

    testWidgets('triggers callbacks for quick actions', (tester) async {
      var absensiTapped = false;
      var checkpointTapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          onAbsensiPressed: () => absensiTapped = true,
          onCheckpointPressed: () => checkpointTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Absensi'));
      await tester.pumpAndSettle();
      expect(absensiTapped, isTrue);

      await tester.tap(find.text('Post to Post Checkpoint'));
      await tester.pumpAndSettle();
      expect(checkpointTapped, isTrue);
    });

    testWidgets('triggers edit callback on shortcuts and management sections', (
      tester,
    ) async {
      var editShortcutsTapped = false;
      var editManagementTapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          onEditShortcutsPressed: () => editShortcutsTapped = true,
          onEditManagementPressed: () => editManagementTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      final shortcutEdit = find.descendant(
        of: find.byType(HomeShortcutsSection),
        matching: find.text('Edit'),
      );
      await tester.tap(shortcutEdit);
      await tester.pumpAndSettle();
      expect(editShortcutsTapped, isTrue);

      final managementEdit = find.descendant(
        of: find.byType(HomeManagementSection),
        matching: find.text('Edit'),
      );
      await tester.ensureVisible(managementEdit);
      await tester.tap(managementEdit);
      await tester.pumpAndSettle();
      expect(editManagementTapped, isTrue);
    });
  });

  group('HomeDashboardView data wiring', () {
    late MockGuestCubit guestCubit;
    late MockIncidentListCubit incidentCubit;

    setUp(() {
      guestCubit = MockGuestCubit();
      incidentCubit = MockIncidentListCubit();
      when(
        () => guestCubit.state,
      ).thenReturn(const GuestLoaded(guests: [], lastSync: ''));
      when(
        () => incidentCubit.state,
      ).thenReturn(const IncidentLoaded(incidents: [], lastSync: ''));
      when(
        () => guestCubit.refreshGuests(
          search: any(named: 'search'),
          filterPeriod: any(named: 'filterPeriod'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          startDateIso: any(named: 'startDateIso'),
          endDateIso: any(named: 'endDateIso'),
          clearCreatorFilter: any(named: 'clearCreatorFilter'),
        ),
      ).thenAnswer((_) async => AppFetchResult.success);
      when(
        () => incidentCubit.refreshIncidents(
          session: any(named: 'session'),
          search: any(named: 'search'),
          filterPeriod: any(named: 'filterPeriod'),
          clearStatusFilter: any(named: 'clearStatusFilter'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          startDateIso: any(named: 'startDateIso'),
          endDateIso: any(named: 'endDateIso'),
        ),
      ).thenAnswer((_) async => AppFetchResult.success);
      when(
        () => incidentCubit.fetchIncidents(session: any(named: 'session')),
      ).thenAnswer((_) async => AppFetchResult.success);
      when(
        guestCubit.fetchGuests,
      ).thenAnswer((_) async => AppFetchResult.success);
    });

    Widget buildWired() {
      return MultiBlocProvider(
        providers: [
          BlocProvider<GuestCubit>.value(value: guestCubit),
          BlocProvider<IncidentListCubit>.value(value: incidentCubit),
          BlocProvider<UserSessionCubit>.value(
            value: UserSessionCubit(_session),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(body: HomeDashboardView()),
        ),
      );
    }

    testWidgets('loads guests and incidents when they were never fetched', (
      tester,
    ) async {
      when(() => guestCubit.state).thenReturn(const GuestInitial());
      when(() => incidentCubit.state).thenReturn(const IncidentInitial());

      await tester.pumpWidget(buildWired());
      await tester.pump();

      verify(guestCubit.fetchGuests).called(1);
      verify(() => incidentCubit.fetchIncidents(session: _session)).called(1);
    });

    testWidgets('does not refetch data that is already loaded', (tester) async {
      await tester.pumpWidget(buildWired());
      await tester.pump();

      verifyNever(guestCubit.fetchGuests);
      verifyNever(() => incidentCubit.fetchIncidents(session: _session));
    });

    testWidgets('pull-to-refresh really refreshes guests and incidents', (
      tester,
    ) async {
      await tester.pumpWidget(buildWired());
      await tester.pumpAndSettle();

      await tester.fling(
        find.text('Tamu Terakhir'),
        const Offset(0, 400),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      verify(
        () => guestCubit.refreshGuests(
          search: '',
          filterPeriod: any(named: 'filterPeriod'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          startDateIso: any(named: 'startDateIso'),
          endDateIso: any(named: 'endDateIso'),
          clearCreatorFilter: true,
        ),
      ).called(1);
      verify(
        () => incidentCubit.refreshIncidents(
          session: _session,
          search: '',
          filterPeriod: any(named: 'filterPeriod'),
          clearStatusFilter: true,
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          startDateIso: any(named: 'startDateIso'),
          endDateIso: any(named: 'endDateIso'),
        ),
      ).called(1);
      expect(find.text('Data beranda berhasil diperbarui.'), findsNothing);
    });

    testWidgets('reports a failed refresh honestly', (tester) async {
      when(
        () => guestCubit.refreshGuests(
          search: any(named: 'search'),
          filterPeriod: any(named: 'filterPeriod'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          startDateIso: any(named: 'startDateIso'),
          endDateIso: any(named: 'endDateIso'),
          clearCreatorFilter: any(named: 'clearCreatorFilter'),
        ),
      ).thenAnswer((_) async => AppFetchResult.failure);

      await tester.pumpWidget(buildWired());
      await tester.pumpAndSettle();
      await tester.fling(
        find.text('Tamu Terakhir'),
        const Offset(0, 400),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Gagal memperbarui data beranda.'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 6));
    });

    testWidgets('incident shortcut shows the number of open incidents', (
      tester,
    ) async {
      when(() => incidentCubit.state).thenReturn(
        IncidentLoaded(
          incidents: [
            _incident('a', IncidentStatus.open),
            _incident('b', IncidentStatus.resolved),
            _incident('c', IncidentStatus.open),
          ],
          lastSync: '',
        ),
      );

      await tester.pumpWidget(buildWired());
      await tester.pumpAndSettle();

      expect(find.text('2 aktif'), findsOneWidget);
      expect(_staticBadgeInShortcuts, findsNothing);
    });

    testWidgets('incident shortcut has no badge without open incidents', (
      tester,
    ) async {
      when(() => incidentCubit.state).thenReturn(
        IncidentLoaded(
          incidents: [_incident('b', IncidentStatus.resolved)],
          lastSync: '',
        ),
      );

      await tester.pumpWidget(buildWired());
      await tester.pumpAndSettle();

      expect(find.textContaining('aktif'), findsNothing);
      expect(_staticBadgeInShortcuts, findsNothing);
    });
  });
}
