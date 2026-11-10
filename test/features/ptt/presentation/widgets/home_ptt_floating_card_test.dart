import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_ptt_floating_card.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_channel_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_floor_state_entity.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/screens/ptt_channel_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockPttCubit extends MockCubit<PttState> implements PttCubit {}

void main() {
  late MockPttCubit mockPttCubit;

  setUp(() {
    mockPttCubit = MockPttCubit();
  });

  Widget buildTestWidget({bool provideCubit = true}) {
    const card = HomePttFloatingCard();
    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: Scaffold(
        body: Center(
          child: provideCubit
              ? BlocProvider<PttCubit>.value(value: mockPttCubit, child: card)
              : card,
        ),
      ),
    );
  }

  group('HomePttFloatingCard Tests', () {
    testWidgets('renders SizedBox.shrink when PttCubit is not provided', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(provideCubit: false));
      await tester.pumpAndSettle();

      expect(find.text('Walkie-Talkie Taktis'), findsNothing);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('renders card in Idle state with member count', (tester) async {
      when(() => mockPttCubit.state).thenReturn(
        const PttIdle(
          channel: PttChannelEntity(groupUid: 'grp_01', memberCount: 8),
          floorState: PttFloorStateEntity(status: PttFloorStatus.idle),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Walkie-Talkie Taktis'), findsOneWidget);
      expect(find.text('8 Anggota Terhubung'), findsOneWidget);
      expect(find.byIcon(Icons.radio_rounded), findsOneWidget);
    });

    testWidgets('does not show a member count before the server sent one', (
      tester,
    ) async {
      when(() => mockPttCubit.state).thenReturn(
        const PttIdle(
          channel: PttChannelEntity(groupUid: 'grp_01'),
          floorState: PttFloorStateEntity.idle(),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Anggota Terhubung'), findsNothing);
      expect(find.text('Saluran terhubung'), findsOneWidget);
    });

    testWidgets('shows connecting text instead of a member count', (
      tester,
    ) async {
      when(() => mockPttCubit.state).thenReturn(
        const PttConnecting(
          channel: PttChannelEntity(groupUid: 'grp_01'),
          floorState: PttFloorStateEntity.idle(),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Menyambung ke saluran...'), findsOneWidget);
    });

    testWidgets('is hidden on iOS where the native PTT engine does not exist', (
      tester,
    ) async {
      when(() => mockPttCubit.state).thenReturn(const PttInitial());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Walkie-Talkie Taktis'), findsNothing);
      expect(find.byType(InkWell), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('renders card in Transmitting state', (tester) async {
      when(() => mockPttCubit.state).thenReturn(
        const PttTransmitting(
          channel: PttChannelEntity(groupUid: 'grp_01'),
          floorState: PttFloorStateEntity(status: PttFloorStatus.transmitting),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Anda Sedang Berbicara'), findsOneWidget);
      expect(
        find.text('Transmisi audio aktif di seluruh regu'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('renders card in Listening state with active speaker name', (
      tester,
    ) async {
      when(() => mockPttCubit.state).thenReturn(
        const PttListening(
          channel: PttChannelEntity(groupUid: 'grp_01'),
          floorState: PttFloorStateEntity(
            status: PttFloorStatus.transmitting,
            speaker: PttSpeakerEntity(
              userId: 'u1',
              name: 'Danru Bambang',
              role: 'ADMIN',
            ),
          ),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Mendengarkan: Danru Bambang'), findsOneWidget);
      expect(find.text('Audio langsung diputar ke speaker'), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    });

    testWidgets('tapping card navigates to PttChannelScreen', (tester) async {
      when(
        () => mockPttCubit.checkAndRequestMicrophonePermission(),
      ).thenAnswer((_) async => true);
      when(() => mockPttCubit.state).thenReturn(
        const PttIdle(
          channel: PttChannelEntity(groupUid: 'grp_01'),
          floorState: PttFloorStateEntity(status: PttFloorStatus.idle),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(HomePttFloatingCard));
      await tester.pumpAndSettle();

      expect(find.byType(PttChannelScreen), findsOneWidget);
    });
  });
}
