import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/widgets/ptt_session_bridge.dart';
import 'package:mocktail/mocktail.dart';

import '../../ptt_member_fixtures.dart';

class MockPttCubit extends MockCubit<PttState> implements PttCubit {}

AuthSessionEntity sessionIn(String? groupUid) => AuthSessionEntity(
  userId: 'usr_1',
  email: 'a@kawalo.id',
  name: 'A',
  allowAdmin: false,
  allowPatrol: false,
  allowMonPatrol: false,
  groupUid: groupUid,
);

void main() {
  late MockPttCubit ptt;

  setUp(() {
    ptt = MockPttCubit();
    when(() => ptt.state).thenReturn(const PttInitial());
    when(() => ptt.joinForGroup(any())).thenAnswer((_) async {});
    when(() => ptt.leaveChannel()).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, UserSessionCubit session) {
    return tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<PttCubit>.value(value: ptt),
          BlocProvider<UserSessionCubit>.value(value: session),
        ],
        // Deliberately no Navigator or PTT screen: the join must not need one.
        child: const PttSessionBridge(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(),
          ),
        ),
      ),
    );
  }

  testWidgets('joins the session group at startup without any screen', (
    tester,
  ) async {
    await pump(tester, UserSessionCubit(sessionIn('grp_1')));
    await tester.pump();

    verify(() => ptt.joinForGroup('grp_1')).called(1);
  });

  testWidgets('joins once a session appears and the group is chosen', (
    tester,
  ) async {
    final session = UserSessionCubit();
    await pump(tester, session);
    await tester.pump();
    verify(() => ptt.joinForGroup(null)).called(1);

    session.updateSession(sessionIn('grp_1'));
    await tester.pump();

    verify(() => ptt.joinForGroup('grp_1')).called(1);
  });

  testWidgets('rejoins with the new group after switch-group', (tester) async {
    final session = UserSessionCubit(sessionIn('grp_1'));
    await pump(tester, session);
    await tester.pump();

    session.updateSession(sessionIn('grp_2'));
    await tester.pump();

    verify(() => ptt.joinForGroup('grp_2')).called(1);
  });

  testWidgets('re-joins when the app comes back to the foreground', (
    tester,
  ) async {
    await pump(tester, UserSessionCubit(sessionIn('grp_1')));
    await tester.pump();
    clearInteractions(ptt);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    verify(() => ptt.joinForGroup('grp_1')).called(1);
  });

  testWidgets('leaves the channel when the session ends', (tester) async {
    when(() => ptt.state).thenReturn(idleState());
    final session = UserSessionCubit(sessionIn('grp_1'));
    await pump(tester, session);
    await tester.pump();

    session.clearSession();
    await tester.pump();

    verify(() => ptt.leaveChannel()).called(1);
  });

  testWidgets('does not start the service just to leave it', (tester) async {
    final session = UserSessionCubit(sessionIn('grp_1'));
    await pump(tester, session);
    await tester.pump();

    session.clearSession();
    await tester.pump();

    verifyNever(() => ptt.leaveChannel());
  });

  testWidgets('never touches the PTT channel on iOS', (tester) async {
    await pump(tester, UserSessionCubit(sessionIn('grp_1')));
    await tester.pump();

    verifyNever(() => ptt.joinForGroup(any()));
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
