import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_channel_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_floor_state_entity.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/widgets/tactical_ptt_button.dart';
import 'package:mocktail/mocktail.dart';

class MockPttCubit extends MockCubit<PttState> implements PttCubit {}

void main() {
  late MockPttCubit mockPttCubit;

  setUp(() {
    mockPttCubit = MockPttCubit();
  });

  Widget buildTestWidget({PttCubit? cubit}) {
    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: Scaffold(
        body: Center(
          child: BlocProvider<PttCubit>.value(
            value: cubit ?? mockPttCubit,
            child: const TacticalPttButton(),
          ),
        ),
      ),
    );
  }

  group('TacticalPttButton Widget Tests', () {
    testWidgets('renders properly in Idle state with min touch target >= 48dp',
        (tester) async {
      when(() => mockPttCubit.state).thenReturn(
        const PttIdle(
          channel: PttChannelEntity(groupUid: 'grp_01'),
          floorState: PttFloorStateEntity(status: PttFloorStatus.idle),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final buttonFinder = find.byType(TacticalPttButton);
      expect(buttonFinder, findsOneWidget);

      final renderBox = tester.renderObject<RenderBox>(buttonFinder);
      expect(
        renderBox.size.width >= AppStateLayer.minTouchTarget,
        isTrue,
      );
      expect(
        renderBox.size.height >= AppStateLayer.minTouchTarget,
        isTrue,
      );

      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    });

    testWidgets('renders active mic icon when state is PttTransmitting',
        (tester) async {
      when(() => mockPttCubit.state).thenReturn(
        const PttTransmitting(
          channel: PttChannelEntity(groupUid: 'grp_01'),
          floorState: PttFloorStateEntity(status: PttFloorStatus.transmitting),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('renders volume icon when state is PttListening',
        (tester) async {
      when(() => mockPttCubit.state).thenReturn(
        const PttListening(
          channel: PttChannelEntity(groupUid: 'grp_01'),
          floorState: PttFloorStateEntity(
            status: PttFloorStatus.transmitting,
            speaker: PttSpeakerEntity(
              userId: 'u1',
              name: 'Danru',
              role: 'ADMIN',
            ),
          ),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    });

    testWidgets('dispatches pressPttButton on pointer down and release on up',
        (tester) async {
      when(() => mockPttCubit.state).thenReturn(
        const PttIdle(
          channel: PttChannelEntity(groupUid: 'grp_01'),
          floorState: PttFloorStateEntity(status: PttFloorStatus.idle),
        ),
      );
      when(() => mockPttCubit.pressPttButton()).thenAnswer((_) async {});
      when(() => mockPttCubit.releasePttButton()).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(TacticalPttButton)),
      );
      await tester.pump();

      verify(() => mockPttCubit.pressPttButton()).called(1);

      await gesture.up();
      await tester.pump();

      verify(() => mockPttCubit.releasePttButton()).called(1);
    });
  });
}
