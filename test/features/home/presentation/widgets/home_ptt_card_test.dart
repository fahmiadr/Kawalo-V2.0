import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_round_action_button.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_ptt_card.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_channel_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_floor_state_entity.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockPttCubit extends MockCubit<PttState> implements PttCubit {}

const _channel = PttChannelEntity(
  groupUid: 'g1',
  connectionStatus: PttConnectionStatus.connected,
  memberCount: 7,
);

void main() {
  late _MockPttCubit cubit;

  setUp(() {
    cubit = _MockPttCubit();
    when(cubit.pressPttButton).thenAnswer((_) async {});
    when(cubit.releasePttButton).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, PttState state) async {
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: BlocProvider<PttCubit>.value(
          value: cubit,
          child: const Scaffold(
            body: Column(
              children: [
                HomeHeader(),
                Expanded(child: HomePttCard()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('idle: hold talks, release stops; count excludes self', (
    tester,
  ) async {
    await pump(
      tester,
      const PttIdle(channel: _channel, floorState: PttFloorStateEntity.idle()),
    );
    expect(find.text('6 rekan online ›'), findsOneWidget);
    expect(find.text('Tahan untuk bicara'), findsOneWidget);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AppRoundActionButton)),
    );
    await tester.pump();
    verify(cubit.pressPttButton).called(1);
    await gesture.up();
    await tester.pump();
    verify(cubit.releasePttButton).called(1);
  });

  testWidgets('listening: speaker on the button and over the header', (
    tester,
  ) async {
    await pump(
      tester,
      const PttListening(
        channel: _channel,
        floorState: PttFloorStateEntity(
          status: PttFloorStatus.transmitting,
          speaker: PttSpeakerEntity(
            userId: '2',
            name: 'Andi R.',
            role: 'GUARD',
          ),
        ),
      ),
    );
    expect(find.text('Andi R. bicara'), findsOneWidget);
    expect(find.text('Andi R. sedang bicara'), findsOneWidget);
    expect(find.text('Tunggu sampai selesai'), findsOneWidget);
  });

  testWidgets('disconnected: banner and no hold action', (tester) async {
    await pump(
      tester,
      const PttReconnecting(
        channel: PttChannelEntity(groupUid: 'g1'),
        floorState: PttFloorStateEntity.idle(),
      ),
    );
    expect(find.text('Terputus'), findsOneWidget);
    expect(
      find.text('Menyambung ulang… Suara belum bisa dikirim.'),
      findsOneWidget,
    );
    await tester.tap(find.byType(AppRoundActionButton));
    verifyNever(cubit.pressPttButton);
  });
}
