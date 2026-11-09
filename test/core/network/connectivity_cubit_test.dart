import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:mocktail/mocktail.dart';

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  group('ConnectivityCubit Unit Tests', () {
    late MockNetworkInfo mockNetworkInfo;
    late StreamController<bool> connectivityStreamController;

    setUp(() {
      mockNetworkInfo = MockNetworkInfo();
      connectivityStreamController = StreamController<bool>.broadcast();
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => mockNetworkInfo.checkConnectivity(),
      ).thenAnswer((_) async => true);
      when(
        () => mockNetworkInfo.checkReachability(),
      ).thenAnswer((_) async => true);
      when(
        () => mockNetworkInfo.onConnectivityChanged,
      ).thenAnswer((_) => connectivityStreamController.stream);
    });

    tearDown(() {
      connectivityStreamController.close();
    });

    test('initial state should be online by default', () {
      final cubit = ConnectivityCubit(
        networkInfo: mockNetworkInfo,
        autoStart: false,
      );
      expect(cubit.state, ConnectivityStatus.online);
      expect(cubit.isOnline, isTrue);
      expect(cubit.isOffline, isFalse);
      cubit.close();
    });

    test('supports custom initialState', () {
      final cubit = ConnectivityCubit(
        networkInfo: mockNetworkInfo,
        initialState: ConnectivityStatus.offline,
        autoStart: false,
      );
      expect(cubit.state, ConnectivityStatus.offline);
      expect(cubit.isOffline, isTrue);
      expect(cubit.isOnline, isFalse);
      cubit.close();
    });

    test(
      'reacts to onConnectivityChanged stream from NetworkInfo (UDF)',
      () async {
        final cubit = ConnectivityCubit(networkInfo: mockNetworkInfo);

        // Sinyalkan perubahan jaringan: internet terputus
        connectivityStreamController.add(false);
        await pumpEventQueue();
        expect(cubit.state, ConnectivityStatus.offline);
        expect(cubit.isOffline, isTrue);

        // Sinyalkan perubahan jaringan: internet pulih
        connectivityStreamController.add(true);
        await pumpEventQueue();
        expect(cubit.state, ConnectivityStatus.online);
        expect(cubit.isOnline, isTrue);

        await cubit.close();
      },
    );

    test(
      'checkNow and checkConnectivity emit new status based on probe',
      () async {
        when(
          () => mockNetworkInfo.checkConnectivity(),
        ).thenAnswer((_) async => false);

        final cubit = ConnectivityCubit(
          networkInfo: mockNetworkInfo,
          autoStart: false,
        );

        await cubit.checkConnectivity();
        expect(cubit.state, ConnectivityStatus.offline);

        when(
          () => mockNetworkInfo.checkConnectivity(),
        ).thenAnswer((_) async => true);
        await cubit.checkNow();
        expect(cubit.state, ConnectivityStatus.online);

        await cubit.close();
      },
    );

    test('re-probes connectivity when lifecycle resumes', () async {
      when(
        () => mockNetworkInfo.checkConnectivity(),
      ).thenAnswer((_) async => true);

      final cubit = ConnectivityCubit(
        networkInfo: mockNetworkInfo,
        initialState: ConnectivityStatus.offline,
        autoStart: false,
      );

      expect(cubit.state, ConnectivityStatus.offline);

      cubit.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(cubit.state, ConnectivityStatus.online);
      verify(() => mockNetworkInfo.checkConnectivity()).called(1);

      await cubit.close();
    });

    test('setStatus directly updates connectivity status for testing', () {
      final cubit = ConnectivityCubit(
        networkInfo: mockNetworkInfo,
        autoStart: false,
      );
      expect(cubit.state, ConnectivityStatus.online);

      cubit.setStatus(ConnectivityStatus.offline);
      expect(cubit.state, ConnectivityStatus.offline);

      cubit.setStatus(ConnectivityStatus.online);
      expect(cubit.state, ConnectivityStatus.online);

      cubit.close();
    });
  });
}
