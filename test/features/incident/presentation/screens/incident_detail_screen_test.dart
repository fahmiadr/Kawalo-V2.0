import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_destructive_button.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_page_actions.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_reply_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_detail_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_detail_state.dart';
import 'package:kawalo_mobile/features/incident/presentation/screens/incident_detail_screen.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_composer_bar.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_resolved_banner.dart';
import 'package:mocktail/mocktail.dart';

class MockIncidentDetailCubit extends Mock implements IncidentDetailCubit {}

void main() {
  late MockIncidentDetailCubit mockCubit;
  late UserSessionCubit userSessionCubit;

  setUp(() {
    mockCubit = MockIncidentDetailCubit();
    userSessionCubit = UserSessionCubit();
  });

  tearDown(() {
    userSessionCubit.close();
  });

  const adminSession = AuthSessionEntity(
    userId: 'usr_admin',
    email: 'admin@kawalo.id',
    name: 'Dewi Sartika',
    role: 'ADMIN',
    groupUid: 'grp_1',
    allowAdmin: true,
    allowPatrol: true,
    allowMonPatrol: true,
  );

  const guardSession = AuthSessionEntity(
    userId: 'usr_guard',
    email: 'budi@kawalo.id',
    name: 'Budi Santoso',
    role: 'GUARD',
    groupUid: 'grp_1',
    allowAdmin: false,
    allowPatrol: true,
    allowMonPatrol: false,
  );

  final tIncident = IncidentEntity(
    id: 'inc_101',
    groupId: 'grp_1',
    title: 'Pintu Gerbang Rusak',
    description: 'Motor menabrak palang barat',
    status: IncidentStatus.open,
    createdBy: 'usr_guard',
    createdByName: 'Budi Santoso',
    createdAt: DateTime.parse('2026-11-04T10:00:00.000Z'),
  );

  final tReply = IncidentReplyEntity(
    id: 'rep_1',
    incidentId: 'inc_101',
    senderId: 'usr_admin',
    senderName: 'Dewi Sartika',
    senderRole: 'admin',
    message: 'Teknisi sedang meluncur ke lokasi.',
    createdAt: DateTime.parse('2026-11-04T10:05:00.000Z'),
  );

  Widget createWidgetUnderTest({
    required IncidentDetailState state,
    EdgeInsets viewPadding = EdgeInsets.zero,
    AuthSessionEntity? session,
  }) {
    if (session != null) userSessionCubit = UserSessionCubit(session);
    when(() => mockCubit.state).thenReturn(state);
    when(() => mockCubit.stream).thenAnswer((_) => Stream.value(state));
    when(
      () => mockCubit.init(session: any(named: 'session')),
    ).thenAnswer((_) async {});
    when(() => mockCubit.close()).thenAnswer((_) async {});
    when(() => mockCubit.pauseStream()).thenReturn(null);
    when(() => mockCubit.resumeStream()).thenReturn(null);

    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(viewPadding: viewPadding, padding: viewPadding),
        child: child!,
      ),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<UserSessionCubit>.value(value: userSessionCubit),
          BlocProvider<IncidentDetailCubit>.value(value: mockCubit),
        ],
        child: const IncidentDetailScreen(incidentId: 'inc_101'),
      ),
    );
  }

  group('IncidentDetailScreen delete placement', () {
    IncidentDetailState openState() => IncidentDetailState(
      status: IncidentDetailStatus.success,
      incident: tIncident,
      replies: [tReply],
    );

    testWidgets('admin gets Hapus Insiden at the bottom, never in the header', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(state: openState(), session: adminSession),
      );
      await tester.pump();

      expect(find.byType(AppPageActions), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppPageActions),
          matching: find.text('Hapus Insiden'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AppHomeAppBar),
          matching: find.textContaining('Hapus'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(AppHomeAppBar),
          matching: find.text('Selesaikan'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('non-admin does not get a delete button', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(state: openState(), session: guardSession),
      );
      await tester.pump();

      expect(find.byType(AppPageActions), findsNothing);
      expect(find.text('Hapus Insiden'), findsNothing);
    });

    testWidgets('delete asks for confirmation naming the incident first', (
      tester,
    ) async {
      when(
        () => mockCubit.deleteIncident(session: any(named: 'session')),
      ).thenAnswer((_) async {});
      await tester.pumpWidget(
        createWidgetUnderTest(state: openState(), session: adminSession),
      );
      await tester.pump();

      await tester.tap(find.text('Hapus Insiden'));
      await tester.pumpAndSettle();

      expect(find.text('Hapus Laporan Insiden?'), findsOneWidget);
      expect(
        find.textContaining('"Pintu Gerbang Rusak" beserta 1 balasan'),
        findsOneWidget,
      );
      verifyNever(
        () => mockCubit.deleteIncident(session: any(named: 'session')),
      );

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      verifyNever(
        () => mockCubit.deleteIncident(session: any(named: 'session')),
      );

      await tester.tap(find.text('Hapus Insiden'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus Insiden').last);
      await tester.pumpAndSettle();

      verify(
        () => mockCubit.deleteIncident(session: any(named: 'session')),
      ).called(1);
    });

    testWidgets('delete bar stays above the system navigation bar inset', (
      tester,
    ) async {
      const navInset = 48.0;
      await tester.pumpWidget(
        createWidgetUnderTest(
          state: openState(),
          session: adminSession,
          viewPadding: const EdgeInsets.only(bottom: navInset),
        ),
      );
      await tester.pump();

      final screenBottom =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(
        tester.getBottomLeft(find.byType(AppDestructiveButton)).dy,
        lessThanOrEqualTo(screenBottom - navInset),
      );
      expect(
        tester.getBottomLeft(find.byType(IncidentComposerBar)).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(AppPageActions)).dy),
      );
    });
  });

  group('IncidentDetailScreen Widget & Accessibility Tests', () {
    testWidgets('renders incident header and reply bubbles correctly', (
      tester,
    ) async {
      final state = IncidentDetailState(
        status: IncidentDetailStatus.success,
        incident: tIncident,
        replies: [tReply],
      );

      await tester.pumpWidget(createWidgetUnderTest(state: state));
      await tester.pump();

      expect(find.text('Pintu Gerbang Rusak'), findsWidgets);
      expect(find.text('Motor menabrak palang barat'), findsOneWidget);
      expect(find.text('Teknisi sedang meluncur ke lokasi.'), findsOneWidget);
      expect(find.byType(IncidentComposerBar), findsOneWidget);
      expect(find.byType(IncidentResolvedBanner), findsNothing);
    });

    testWidgets(
      'displays IncidentResolvedBanner and hides composer when isReadOnly '
      'is true',
      (tester) async {
        final resolvedIncident = tIncident.copyWith(
          status: IncidentStatus.resolved,
          resolvedBy: 'usr_admin',
          resolvedByName: 'Dewi Sartika',
          resolvedAt: DateTime.parse('2026-11-04T10:20:00.000Z'),
        );

        final state = IncidentDetailState(
          status: IncidentDetailStatus.success,
          incident: resolvedIncident,
          replies: [tReply],
          isReadOnly: true,
        );

        await tester.pumpWidget(createWidgetUnderTest(state: state));
        await tester.pump();

        expect(find.byType(IncidentResolvedBanner), findsOneWidget);
        expect(find.byType(IncidentComposerBar), findsNothing);
        expect(find.textContaining('Dewi Sartika'), findsWidgets);
      },
    );

    testWidgets('keeps the composer above the system navigation bar inset', (
      tester,
    ) async {
      const navInset = 48.0;
      final state = IncidentDetailState(
        status: IncidentDetailStatus.success,
        incident: tIncident,
        replies: [tReply],
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          state: state,
          viewPadding: const EdgeInsets.only(bottom: navInset),
        ),
      );
      await tester.pump();

      final screenBottom =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final composerBottom = tester
          .getBottomLeft(find.byType(IncidentComposerBar))
          .dy;
      expect(composerBottom, lessThanOrEqualTo(screenBottom - navInset));
    });

    testWidgets('keeps the resolved banner above the system navigation bar', (
      tester,
    ) async {
      const navInset = 48.0;
      final state = IncidentDetailState(
        status: IncidentDetailStatus.success,
        incident: tIncident.copyWith(status: IncidentStatus.resolved),
        replies: [tReply],
        isReadOnly: true,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          state: state,
          viewPadding: const EdgeInsets.only(bottom: navInset),
        ),
      );
      await tester.pump();

      final screenBottom =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final bannerBottom = tester
          .getBottomLeft(find.byType(IncidentResolvedBanner))
          .dy;
      expect(bannerBottom, lessThanOrEqualTo(screenBottom - navInset));
    });

    testWidgets('renders without overflow under 200% dynamic text scaling', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(
        () => tester.platformDispatcher.clearTextScaleFactorTestValue(),
      );

      final state = IncidentDetailState(
        status: IncidentDetailStatus.success,
        incident: tIncident,
        replies: [tReply],
      );

      await tester.pumpWidget(createWidgetUnderTest(state: state));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
