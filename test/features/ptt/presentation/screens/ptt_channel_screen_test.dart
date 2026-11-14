import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_members_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_members_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/screens/ptt_channel_screen.dart';
import 'package:kawalo_mobile/features/ptt/presentation/widgets/tactical_ptt_button.dart';
import 'package:mocktail/mocktail.dart';

import '../../ptt_member_fixtures.dart';

class MockPttCubit extends MockCubit<PttState> implements PttCubit {}

class MockMembersCubit extends MockCubit<PttMembersState>
    implements PttMembersCubit {}

class MockApiClient extends Mock implements ApiClient {}

void main() {
  testWidgets('a long member list scrolls while the PTT button stays on '
      'screen on a small phone', (tester) async {
    tester.view
      ..physicalSize = const Size(320 * 2, 568 * 2)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final ptt = MockPttCubit();
    final members = MockMembersCubit();
    when(() => ptt.state).thenReturn(idleState(memberCount: 20));
    when(ptt.checkAndRequestMicrophonePermission).thenAnswer((_) async => true);
    when(() => members.state).thenReturn(
      PttMembersState(
        isLoading: false,
        members: [for (var i = 0; i < 20; i++) member('usr_$i')],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: RepositoryProvider<ApiClient>.value(
          value: MockApiClient(),
          child: MultiBlocProvider(
            providers: [
              BlocProvider<PttCubit>.value(value: ptt),
              BlocProvider<PttMembersCubit>.value(value: members),
            ],
            child: const PttChannelScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final button = tester.getRect(find.byType(TacticalPttButton));
    expect(button.bottom, lessThanOrEqualTo(568));
    expect(button.top, greaterThan(0));

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -2000),
    );
    await tester.pump();

    expect(find.text('20 rekan online'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.byType(TacticalPttButton)), button);
  });
}
