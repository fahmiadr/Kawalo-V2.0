import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
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

  Widget createWidgetUnderTest({required IncidentDetailState state}) {
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
      home: MultiBlocProvider(
        providers: [
          BlocProvider<UserSessionCubit>.value(value: userSessionCubit),
          BlocProvider<IncidentDetailCubit>.value(value: mockCubit),
        ],
        child: const IncidentDetailScreen(incidentId: 'inc_101'),
      ),
    );
  }

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
