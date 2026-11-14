import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_members_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_members_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/widgets/ptt_member_list.dart';
import 'package:mocktail/mocktail.dart';

import '../../ptt_member_fixtures.dart';
import '../../ptt_recording_fixtures.dart';

class MockPttCubit extends MockCubit<PttState> implements PttCubit {}

class MockMembersCubit extends MockCubit<PttMembersState>
    implements PttMembersCubit {}

void main() {
  late MockPttCubit ptt;
  late MockMembersCubit members;

  setUp(() {
    ptt = MockPttCubit();
    members = MockMembersCubit();
  });

  Future<void> pump(
    WidgetTester tester,
    PttMembersState membersState, {
    PttState? pttState,
  }) async {
    when(() => ptt.state).thenReturn(pttState ?? idleState());
    when(() => members.state).thenReturn(membersState);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<PttCubit>.value(value: ptt),
            BlocProvider<PttMembersCubit>.value(value: members),
            // session() is user "usr_me".
            BlocProvider<UserSessionCubit>.value(
              value: UserSessionCubit(session()),
            ),
          ],
          child: const Scaffold(
            body: SingleChildScrollView(child: PttMemberList()),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  final roster = PttMembersState(
    isLoading: false,
    members: [
      member('usr_z', name: 'Zainal', role: 'ADMIN'),
      member('usr_me', name: 'Saya'),
      member('usr_b', name: 'budi'),
      member('usr_a', name: 'Agus'),
    ],
  );

  testWidgets('hands each member photo to the avatar', (tester) async {
    await pump(
      tester,
      PttMembersState(
        isLoading: false,
        members: [
          member('usr_a', name: 'Agus', avatarUrl: 'https://h/uploads/a.webp'),
          member('usr_b', name: 'Budi'),
        ],
      ),
    );

    final urls = tester
        .widgetList<AppUserAvatar>(find.byType(AppUserAvatar))
        .map((a) => a.imageUrl);
    expect(urls, ['https://h/uploads/a.webp', null]);
  });

  testWidgets('counts colleagues, not the current user', (tester) async {
    await pump(tester, roster);

    expect(find.text('3 rekan online'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Petugas'), findsNWidgets(3));
  });

  testWidgets('nobody speaks, and the current user is marked Anda', (
    tester,
  ) async {
    await pump(tester, roster);

    expect(find.text('Bicara'), findsNothing);
    expect(find.text('Sedang bicara'), findsNothing);
    expect(find.text('Anda'), findsOneWidget);
  });

  testWidgets('the live floor speaker is Bicara and listed first', (
    tester,
  ) async {
    await pump(tester, roster, pttState: listeningState(speakerId: 'usr_z'));

    expect(find.text('Bicara'), findsOneWidget);
    expect(find.text('Sedang bicara'), findsOneWidget);
    final order = [
      'Zainal',
      'Agus',
      'budi',
      'Saya',
    ].map((n) => tester.getTopLeft(find.text(n)).dy).toList();
    expect(order, orderedEquals([...order]..sort()));
  });

  testWidgets('others are sorted alphabetically, case-insensitively', (
    tester,
  ) async {
    await pump(tester, roster);

    final order = [
      'Agus',
      'budi',
      'Saya',
      'Zainal',
    ].map((n) => tester.getTopLeft(find.text(n)).dy).toList();
    expect(order, orderedEquals([...order]..sort()));
  });

  testWidgets('the speaking flag of a stale fetch is not trusted', (
    tester,
  ) async {
    final stale = PttMembersState(
      isLoading: false,
      members: [member('usr_a', name: 'Agus', speaking: true)],
    );

    await pump(tester, stale);

    expect(find.text('Bicara'), findsNothing);
  });

  testWidgets('while this user transmits they are the speaker', (tester) async {
    final idle = idleState();
    await pump(
      tester,
      roster,
      pttState: PttTransmitting(
        channel: idle.channel,
        floorState: idle.floorState,
      ),
    );

    expect(find.text('Bicara'), findsOneWidget);
    expect(
      find.descendant(
        of: find
            .ancestor(of: find.text('Saya'), matching: find.byType(Row))
            .first,
        matching: find.text('Anda'),
      ),
      findsOneWidget,
    );
    final saya = tester.getTopLeft(find.text('Saya')).dy;
    expect(saya, lessThan(tester.getTopLeft(find.text('Agus')).dy));
  });

  testWidgets('shows a skeleton before the first answer', (tester) async {
    await pump(tester, const PttMembersState());

    expect(find.text('Rekan online'), findsOneWidget);
    expect(find.bySemanticsLabel('Memuat daftar rekan'), findsOneWidget);
  });

  testWidgets('shows an empty state when nobody is online', (tester) async {
    await pump(tester, const PttMembersState(isLoading: false));

    expect(find.text('Belum ada rekan online.'), findsOneWidget);
  });

  testWidgets('a failure keeps the list and offers a retry', (tester) async {
    when(() => members.retry()).thenAnswer((_) async {});
    await pump(
      tester,
      PttMembersState(
        isLoading: false,
        failed: true,
        members: [member('usr_a', name: 'Agus')],
      ),
    );

    expect(find.text('Agus'), findsOneWidget);
    expect(find.text('Gagal memuat daftar rekan'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    verify(() => members.retry()).called(1);
  });
}
