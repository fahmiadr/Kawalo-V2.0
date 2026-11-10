import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_reply_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_detail_state.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_detail/incident_detail_body.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_thread_bubble.dart';

void main() {
  final tIncident = IncidentEntity(
    id: 'inc_1',
    groupId: 'grp_1',
    title: 'Pintu Gerbang Rusak',
    status: IncidentStatus.open,
    createdBy: 'guard@kawalo.id',
    createdAt: DateTime.parse('2026-11-04T10:00:00.000Z'),
  );

  IncidentReplyEntity reply(String id, String senderId) => IncidentReplyEntity(
    id: id,
    incidentId: 'inc_1',
    senderId: senderId,
    senderName: 'Pengirim $id',
    senderRole: 'GUARD',
    message: 'Pesan $id',
    createdAt: DateTime.parse('2026-11-04T10:05:00.000Z'),
  );

  const session = AuthSessionEntity(
    userId: 'a1b2c3-sub-claim',
    email: 'Guard@Kawalo.id',
    name: 'Budi',
    allowAdmin: false,
    allowPatrol: true,
    allowMonPatrol: false,
    groupUid: 'grp_1',
  );

  Future<void> pump(
    WidgetTester tester, {
    required List<IncidentReplyEntity> replies,
    AuthSessionEntity? session,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: Scaffold(
          body: IncidentDetailBody(
            state: IncidentDetailState(
              status: IncidentDetailStatus.success,
              incident: tIncident,
              replies: replies,
            ),
            session: session,
            scrollController: ScrollController(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  bool isMeOf(WidgetTester tester, String message) {
    final bubble = find.ancestor(
      of: find.text(message),
      matching: find.byType(IncidentThreadBubble),
    );
    return tester.widget<IncidentThreadBubble>(bubble).isMe;
  }

  testWidgets(
    'own replies match the session email case-insensitively, not the JWT sub',
    (tester) async {
      await pump(
        tester,
        session: session,
        replies: [
          reply('mine', 'guard@kawalo.id'),
          reply('sub', 'a1b2c3-sub-claim'),
          reply('other', 'dewi@kawalo.id'),
        ],
      );

      expect(isMeOf(tester, 'Pesan mine'), isTrue);
      expect(isMeOf(tester, 'Pesan sub'), isFalse);
      expect(isMeOf(tester, 'Pesan other'), isFalse);
    },
  );

  testWidgets('without a session no reply is treated as own', (tester) async {
    await pump(tester, replies: [reply('mine', 'guard@kawalo.id')]);

    expect(isMeOf(tester, 'Pesan mine'), isFalse);
  });
}
