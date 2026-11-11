import 'dart:async';
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_channel_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_floor_state_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_repository.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/join_channel/join_channel_params.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/join_channel/join_channel_usecase.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/start_transmission/start_transmission_params.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/start_transmission/start_transmission_usecase.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockPttRepository extends Mock implements PttRepository {}

class MockJoinChannelUseCase extends Mock implements JoinChannelUseCase {}

class MockStartTransmissionUseCase extends Mock
    implements StartTransmissionUseCase {}

void main() {
  late MockPttRepository mockRepository;
  late MockJoinChannelUseCase mockJoinChannel;
  late MockStartTransmissionUseCase mockStartTransmission;

  late StreamController<PttFloorStateEntity> floorController;
  late StreamController<PttConnectionStatus> connectionController;
  late StreamController<int> memberCountController;
  late StreamController<Map<String, dynamic>> transmissionController;
  late StreamController<void> authRejectedController;

  setUpAll(() {
    registerFallbackValue(
      const JoinChannelParams(
        channelUrl: 'wss://test',
        groupUid: 'grp_1',
        token: 'token_1',
      ),
    );
    registerFallbackValue(const StartTransmissionParams(requestId: 'req_1'));
  });

  setUp(() {
    mockRepository = MockPttRepository();
    mockJoinChannel = MockJoinChannelUseCase();
    mockStartTransmission = MockStartTransmissionUseCase();

    floorController = StreamController<PttFloorStateEntity>.broadcast();
    connectionController = StreamController<PttConnectionStatus>.broadcast();
    memberCountController = StreamController<int>.broadcast();
    transmissionController = StreamController<Map<String, dynamic>>.broadcast();
    authRejectedController = StreamController<void>.broadcast();

    when(
      () => mockRepository.watchFloorState(),
    ).thenAnswer((_) => floorController.stream);
    when(
      () => mockRepository.watchConnectionStatus(),
    ).thenAnswer((_) => connectionController.stream);
    when(
      () => mockRepository.watchMemberCount(),
    ).thenAnswer((_) => memberCountController.stream);
    when(
      () => mockRepository.watchTransmissionEvents(),
    ).thenAnswer((_) => transmissionController.stream);
    when(
      () => mockRepository.watchAuthRejected(),
    ).thenAnswer((_) => authRejectedController.stream);
    when(
      () => mockRepository.hasRecordAudioPermission(),
    ).thenAnswer((_) async => true);
    when(
      () => mockRepository.requestRecordAudioPermission(),
    ).thenAnswer((_) async => true);
  });

  tearDown(() {
    floorController.close();
    connectionController.close();
    memberCountController.close();
    transmissionController.close();
    authRejectedController.close();
  });

  PttCubit createCubit({
    SecureStorageService? storage,
    String baseUrl = 'https://api.kawalo.id',
    Future<void> Function()? refresh,
  }) {
    return PttCubit(
      joinChannelUseCase: mockJoinChannel,
      startTransmissionUseCase: mockStartTransmission,
      repository: mockRepository,
      storageService: storage,
      apiBaseUrl: () => baseUrl,
      refreshAccessToken: refresh,
    );
  }

  group('PttCubit', () {
    test('initial state is PttInitial', () {
      final cubit = createCubit();
      expect(cubit.state, const PttInitial());
      cubit.close();
    });

    blocTest<PttCubit, PttState>(
      'joinChannel emits PttConnecting when invoked',
      setUp: () {
        when(
          () => mockJoinChannel(any()),
        ).thenAnswer((_) async => const Right(null));
      },
      build: createCubit,
      act: (cubit) => cubit.joinChannel(
        channelUrl: 'wss://test',
        groupUid: 'grp_01',
        token: 'tok_01',
      ),
      expect: () => [
        const PttConnecting(
          channel: PttChannelEntity(
            groupUid: 'grp_01',
            connectionStatus: PttConnectionStatus.connecting,
          ),
          floorState: PttFloorStateEntity(status: PttFloorStatus.idle),
        ),
      ],
    );

    blocTest<PttCubit, PttState>(
      'joinChannel emits PttDisconnected if usecase returns Failure',
      setUp: () {
        when(() => mockJoinChannel(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Connection refused')),
        );
      },
      build: createCubit,
      act: (cubit) => cubit.joinChannel(
        channelUrl: 'wss://test',
        groupUid: 'grp_01',
        token: 'tok_01',
      ),
      expect: () => [
        const PttConnecting(
          channel: PttChannelEntity(
            groupUid: 'grp_01',
            connectionStatus: PttConnectionStatus.connecting,
          ),
          floorState: PttFloorStateEntity(status: PttFloorStatus.idle),
        ),
        const PttDisconnected(
          channel: PttChannelEntity(groupUid: 'grp_01'),
          floorState: PttFloorStateEntity(status: PttFloorStatus.idle),
          errorMessage: 'Connection refused',
        ),
      ],
    );

    blocTest<PttCubit, PttState>(
      'pressPttButton emits PttRequestingFloor and calls usecase',
      setUp: () {
        when(
          () => mockStartTransmission(any()),
        ).thenAnswer((_) async => const Right(null));
      },
      build: createCubit,
      seed: () => const PttIdle(
        channel: PttChannelEntity(
          groupUid: 'grp_01',
          connectionStatus: PttConnectionStatus.connected,
        ),
        floorState: PttFloorStateEntity(status: PttFloorStatus.idle),
      ),
      act: (cubit) => cubit.pressPttButton(),
      expect: () => [
        isA<PttRequestingFloor>().having(
          (s) => s.channel.groupUid,
          'groupUid',
          'grp_01',
        ),
      ],
      verify: (_) {
        verify(() => mockStartTransmission(any())).called(1);
      },
    );

    blocTest<PttCubit, PttState>(
      'pressPttButton is ignored when already transmitting',
      build: createCubit,
      seed: () => const PttTransmitting(
        channel: PttChannelEntity(groupUid: 'grp_01'),
        floorState: PttFloorStateEntity(status: PttFloorStatus.transmitting),
      ),
      act: (cubit) => cubit.pressPttButton(),
      expect: () => <PttState>[],
      verify: (_) {
        verifyZeroInteractions(mockStartTransmission);
      },
    );

    blocTest<PttCubit, PttState>(
      'releasePttButton calls stopTransmission and emits PttIdle',
      setUp: () {
        when(
          () => mockRepository.stopTransmission(),
        ).thenAnswer((_) async => const Right(null));
      },
      build: createCubit,
      seed: () => const PttTransmitting(
        channel: PttChannelEntity(groupUid: 'grp_01'),
        floorState: PttFloorStateEntity(status: PttFloorStatus.transmitting),
      ),
      act: (cubit) => cubit.releasePttButton(),
      expect: () => [
        const PttIdle(
          channel: PttChannelEntity(groupUid: 'grp_01'),
          floorState: PttFloorStateEntity(status: PttFloorStatus.idle),
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.stopTransmission()).called(1);
      },
    );

    blocTest<PttCubit, PttState>(
      'reacts to transmission GRANTED event by emitting PttTransmitting',
      build: createCubit,
      seed: () => const PttRequestingFloor(
        channel: PttChannelEntity(groupUid: 'grp_01'),
        floorState: PttFloorStateEntity(status: PttFloorStatus.idle),
        requestId: 'req_123',
      ),
      act: (_) {
        transmissionController.add({'state': 'GRANTED', 'leaseTtlMs': 2000});
      },
      expect: () => [
        const PttTransmitting(
          channel: PttChannelEntity(groupUid: 'grp_01'),
          floorState: PttFloorStateEntity(status: PttFloorStatus.idle),
        ),
      ],
    );

    blocTest<PttCubit, PttState>(
      'reacts to transmission DENIED event by emitting PttFloorDenied',
      build: createCubit,
      seed: () => const PttRequestingFloor(
        channel: PttChannelEntity(groupUid: 'grp_01'),
        floorState: PttFloorStateEntity(status: PttFloorStatus.idle),
        requestId: 'req_123',
      ),
      act: (_) {
        transmissionController.add({
          'state': 'DENIED',
          'reason': 'CHANNEL_BUSY',
        });
      },
      expect: () => [
        const PttFloorDenied(
          channel: PttChannelEntity(groupUid: 'grp_01'),
          floorState: PttFloorStateEntity(status: PttFloorStatus.idle),
          reason: 'CHANNEL_BUSY',
        ),
      ],
    );

    blocTest<PttCubit, PttState>(
      'reacts to transmission REVOKED (preempted) by emitting PttListening',
      build: createCubit,
      seed: () => const PttTransmitting(
        channel: PttChannelEntity(groupUid: 'grp_01'),
        floorState: PttFloorStateEntity(status: PttFloorStatus.transmitting),
      ),
      act: (_) {
        transmissionController.add({
          'state': 'REVOKED',
          'preemptedBy': 'Commander Danru',
        });
      },
      expect: () => [
        const PttListening(
          channel: PttChannelEntity(groupUid: 'grp_01'),
          floorState: PttFloorStateEntity(status: PttFloorStatus.transmitting),
          preemptedBy: 'Commander Danru',
        ),
      ],
    );

    blocTest<PttCubit, PttState>(
      'reacts to floor occupied by emitting PttListening',
      build: createCubit,
      seed: () => const PttIdle(
        channel: PttChannelEntity(groupUid: 'grp_01'),
        floorState: PttFloorStateEntity(status: PttFloorStatus.idle),
      ),
      act: (_) {
        floorController.add(
          const PttFloorStateEntity(
            status: PttFloorStatus.transmitting,
            speaker: PttSpeakerEntity(
              userId: 'usr_speaker',
              name: 'Sgt. Budi',
              role: 'GUARD',
            ),
          ),
        );
      },
      expect: () => [
        const PttListening(
          channel: PttChannelEntity(groupUid: 'grp_01'),
          floorState: PttFloorStateEntity(
            status: PttFloorStatus.transmitting,
            speaker: PttSpeakerEntity(
              userId: 'usr_speaker',
              name: 'Sgt. Budi',
              role: 'GUARD',
            ),
          ),
        ),
      ],
    );

    blocTest<PttCubit, PttState>(
      'reacts to connection reconnecting event by emitting PttReconnecting',
      build: createCubit,
      act: (_) {
        connectionController.add(PttConnectionStatus.reconnecting);
      },
      expect: () => [
        const PttReconnecting(
          channel: PttChannelEntity(
            groupUid: '',
            connectionStatus: PttConnectionStatus.reconnecting,
          ),
          floorState: PttFloorStateEntity(status: PttFloorStatus.idle),
        ),
      ],
    );

    blocTest<PttCubit, PttState>(
      'leaveChannel invokes repository.leaveChannel and emits PttInitial',
      setUp: () {
        when(
          () => mockRepository.leaveChannel(),
        ).thenAnswer((_) async => const Right(null));
      },
      build: createCubit,
      seed: () => const PttIdle(
        channel: PttChannelEntity(groupUid: 'grp_01'),
        floorState: PttFloorStateEntity(status: PttFloorStatus.idle),
      ),
      act: (cubit) => cubit.leaveChannel(),
      expect: () => [const PttInitial()],
      verify: (_) {
        verify(() => mockRepository.leaveChannel()).called(1);
      },
    );

    blocTest<PttCubit, PttState>(
      'pressPttButton emits PttFloorDenied when microphone permission '
      'is denied',
      setUp: () {
        when(
          () => mockRepository.hasRecordAudioPermission(),
        ).thenAnswer((_) async => false);
        when(
          () => mockRepository.requestRecordAudioPermission(),
        ).thenAnswer((_) async => false);
      },
      build: createCubit,
      seed: () => const PttIdle(
        channel: PttChannelEntity(groupUid: 'grp_01'),
        floorState: PttFloorStateEntity(status: PttFloorStatus.idle),
      ),
      act: (cubit) => cubit.pressPttButton(),
      expect: () => [
        const PttFloorDenied(
          channel: PttChannelEntity(groupUid: 'grp_01'),
          floorState: PttFloorStateEntity(status: PttFloorStatus.idle),
          reason: 'PERMISSION_DENIED',
        ),
      ],
      verify: (_) {
        verifyZeroInteractions(mockStartTransmission);
      },
    );
  });

  group('PttCubit.joinForGroup', () {
    late MockSecureStorageService storage;

    setUp(() {
      storage = MockSecureStorageService();
      when(storage.getAccessToken).thenAnswer((_) async => 'tok');
      when(
        () => mockJoinChannel(any()),
      ).thenAnswer((_) async => const Right(null));
    });

    JoinChannelParams captured() =>
        verify(() => mockJoinChannel(captureAny())).captured.single
            as JoinChannelParams;

    test(
      'builds a wss URL from an https base and joins with the token',
      () async {
        final cubit = createCubit(storage: storage);

        await cubit.joinForGroup('grp_01');

        final params = captured();
        expect(params.channelUrl, 'wss://api.kawalo.id/ws/ptt/grp_01');
        expect(params.groupUid, 'grp_01');
        expect(params.token, 'tok');
        await cubit.close();
      },
    );

    test('builds a ws URL keeping the port for an http base', () async {
      final cubit = createCubit(
        storage: storage,
        baseUrl: 'http://10.0.2.2:3000/api',
      );

      await cubit.joinForGroup('grp_01');

      expect(captured().channelUrl, 'ws://10.0.2.2:3000/ws/ptt/grp_01');
      await cubit.close();
    });

    for (final groupUid in <String?>[null, '']) {
      test('does nothing for group "$groupUid"', () async {
        final cubit = createCubit(storage: storage);

        await cubit.joinForGroup(groupUid);

        verifyNever(() => mockJoinChannel(any()));
        await cubit.close();
      });
    }

    test('does nothing without a stored token', () async {
      when(storage.getAccessToken).thenAnswer((_) async => '');
      final cubit = createCubit(storage: storage);

      await cubit.joinForGroup('grp_01');

      verifyNever(() => mockJoinChannel(any()));
      await cubit.close();
    });

    test('does nothing without storage', () async {
      final cubit = createCubit();

      await cubit.joinForGroup('grp_01');

      verifyNever(() => mockJoinChannel(any()));
      await cubit.close();
    });

    test('does nothing while a channel is already active', () async {
      final cubit = createCubit(storage: storage)
        ..emit(
          const PttIdle(
            channel: PttChannelEntity(groupUid: 'grp_01'),
            floorState: PttFloorStateEntity(status: PttFloorStatus.idle),
          ),
        );

      await cubit.joinForGroup('grp_01');

      verifyNever(() => mockJoinChannel(any()));
      await cubit.close();
    });

    test('rejoins from PttDisconnected', () async {
      final cubit = createCubit(storage: storage)
        ..emit(
          const PttDisconnected(
            channel: PttChannelEntity(groupUid: 'grp_01'),
            floorState: PttFloorStateEntity(status: PttFloorStatus.idle),
          ),
        );

      await cubit.joinForGroup('grp_01');

      verify(() => mockJoinChannel(any())).called(1);
      await cubit.close();
    });

    test('leaves the old group channel before joining a new group', () async {
      final calls = <String>[];
      when(() => mockRepository.leaveChannel()).thenAnswer((_) async {
        calls.add('leave');
        return const Right(null);
      });
      when(() => mockJoinChannel(any())).thenAnswer((_) async {
        calls.add('join');
        return const Right(null);
      });
      final cubit = createCubit(storage: storage)
        ..emit(
          const PttIdle(
            channel: PttChannelEntity(groupUid: 'grp_01'),
            floorState: PttFloorStateEntity.idle(),
          ),
        );

      await cubit.joinForGroup('grp_02');

      expect(calls, ['leave', 'join']);
      expect(cubit.state.channel.groupUid, 'grp_02');
      await cubit.close();
    });

    test('does not leave when the same group is already joined', () async {
      final cubit = createCubit(storage: storage)
        ..emit(
          const PttIdle(
            channel: PttChannelEntity(groupUid: 'grp_01'),
            floorState: PttFloorStateEntity.idle(),
          ),
        );

      await cubit.joinForGroup('grp_01');

      verifyNever(() => mockRepository.leaveChannel());
      verifyNever(() => mockJoinChannel(any()));
      await cubit.close();
    });

    test('does nothing on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final cubit = createCubit(storage: storage);

      await cubit.joinForGroup('grp_01');

      verifyNever(() => mockJoinChannel(any()));
      await cubit.close();
    });

    test('swallows storage and URL failures', () async {
      when(storage.getAccessToken).thenThrow(StateError('boom'));
      final cubit = createCubit(storage: storage);

      await expectLater(cubit.joinForGroup('grp_01'), completes);

      verifyNever(() => mockJoinChannel(any()));
      await cubit.close();
    });
  });

  group('PttCubit token freshness', () {
    late MockSecureStorageService storage;

    setUp(() {
      storage = MockSecureStorageService();
      when(
        () => mockJoinChannel(any()),
      ).thenAnswer((_) async => const Right(null));
    });

    String jwt({required Duration validFor}) {
      String part(Map<String, Object> m) =>
          base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
      final exp = DateTime.now().add(validFor).millisecondsSinceEpoch ~/ 1000;
      return '${part({'alg': 'none'})}.${part({'exp': exp})}.sig';
    }

    test('an expired stored token is refreshed before joining', () async {
      final fresh = jwt(validFor: const Duration(minutes: 15));
      final tokens = [jwt(validFor: const Duration(minutes: -5)), fresh];
      when(storage.getAccessToken).thenAnswer((_) async => tokens.removeAt(0));
      var refreshed = 0;
      final cubit = createCubit(
        storage: storage,
        refresh: () async => refreshed++,
      );

      await cubit.joinForGroup('grp_01');

      expect(refreshed, 1);
      final params =
          verify(() => mockJoinChannel(captureAny())).captured.single
              as JoinChannelParams;
      expect(params.token, fresh);
      await cubit.close();
    });

    test('a still valid token is not refreshed', () async {
      when(
        storage.getAccessToken,
      ).thenAnswer((_) async => jwt(validFor: const Duration(minutes: 10)));
      var refreshed = 0;
      final cubit = createCubit(
        storage: storage,
        refresh: () async => refreshed++,
      );

      await cubit.joinForGroup('grp_01');

      expect(refreshed, 0);
      verify(() => mockJoinChannel(any())).called(1);
      await cubit.close();
    });

    test('a failing refresh does not stop the join', () async {
      when(
        storage.getAccessToken,
      ).thenAnswer((_) async => jwt(validFor: const Duration(minutes: -5)));
      final cubit = createCubit(
        storage: storage,
        refresh: () async => throw StateError('offline'),
      );

      await cubit.joinForGroup('grp_01');

      verify(() => mockJoinChannel(any())).called(1);
      await cubit.close();
    });

    test(
      'a native 401 refreshes the token, at most once per cooldown',
      () async {
        var refreshed = 0;
        final cubit = createCubit(refresh: () async => refreshed++);

        authRejectedController
          ..add(null)
          ..add(null)
          ..add(null);
        await Future<void>.delayed(Duration.zero);

        expect(refreshed, 1);
        await cubit.close();
      },
    );

    test('a native 401 without a refresh hook is ignored', () async {
      final cubit = createCubit();

      authRejectedController.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, const PttInitial());
      await cubit.close();
    });
  });
}
