import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_channel_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_floor_state_entity.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/widgets/ptt_channel_header.dart';
import 'package:mocktail/mocktail.dart';

class MockPttCubit extends MockCubit<PttState> implements PttCubit {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockPttCubit pttCubit;

  setUp(() {
    pttCubit = MockPttCubit();
  });

  Widget build({
    AuthBloc? authBloc,
    PttConnectionStatus status = PttConnectionStatus.connected,
  }) {
    when(() => pttCubit.state).thenReturn(
      PttIdle(
        channel: PttChannelEntity(groupUid: 'grp_1', connectionStatus: status),
        floorState: const PttFloorStateEntity.idle(),
      ),
    );
    Widget child = BlocProvider<PttCubit>.value(
      value: pttCubit,
      child: const Scaffold(body: PttChannelHeader()),
    );
    if (authBloc != null) {
      child = BlocProvider<AuthBloc>.value(value: authBloc, child: child);
    }
    return MaterialApp(theme: AppTheme.lightThemeData(), home: child);
  }

  testWidgets('falls back to a generic channel name without a session', (
    tester,
  ) async {
    await tester.pumpWidget(build());

    expect(find.text('Walkie-talkie'), findsOneWidget);
    expect(find.text('Kanal grup · Terhubung'), findsOneWidget);
  });

  testWidgets('names the channel after the active group', (tester) async {
    final authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(
      const Authenticated(
        user: UserEntity(
          id: 'usr_1',
          email: 'a@kawalo.id',
          name: 'Admin',
          groups: [],
          activeGroup: UserGroupEntity(
            groupUid: 'grp_1',
            groupName: 'Kawasan Veranda',
            allowAdmin: true,
            allowPatrol: false,
            allowMonPatrol: false,
            features: [],
          ),
        ),
      ),
    );

    await tester.pumpWidget(build(authBloc: authBloc));

    expect(find.text('Kawasan Veranda · Terhubung'), findsOneWidget);
  });

  testWidgets('reports a dropped connection', (tester) async {
    await tester.pumpWidget(build(status: PttConnectionStatus.reconnecting));
    expect(find.text('Kanal grup · Menyambung…'), findsOneWidget);

    // A fresh tree: a mocked cubit does not stream the new state.
    await tester.pumpWidget(const SizedBox());

    await tester.pumpWidget(build(status: PttConnectionStatus.disconnected));
    expect(find.text('Kanal grup · Terputus'), findsOneWidget);
  });
}
