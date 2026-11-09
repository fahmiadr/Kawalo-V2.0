import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  group('NetworkInfoImpl Unit Tests', () {
    late MockConnectivity mockConnectivity;
    late StreamController<List<ConnectivityResult>>
    connectivityStreamController;

    setUp(() {
      mockConnectivity = MockConnectivity();
      connectivityStreamController =
          StreamController<List<ConnectivityResult>>.broadcast();

      when(
        () => mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => connectivityStreamController.stream);
    });

    tearDown(() {
      connectivityStreamController.close();
    });

    test(
      'isConnected returns false immediately if no network interface',
      () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.none]);

        var checkProbeCalled = false;
        final networkInfo = NetworkInfoImpl(
          connectivity: mockConnectivity,
          checkConnection: () async {
            checkProbeCalled = true;
            return true;
          },
        );

        final result = await networkInfo.isConnected;
        expect(result, isFalse);
        expect(checkProbeCalled, isFalse);
        networkInfo.dispose();
      },
    );

    test(
      'isConnected runs active check probe when interface is available',
      () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);

        var checkProbeCalled = false;
        final networkInfo = NetworkInfoImpl(
          connectivity: mockConnectivity,
          checkConnection: () async {
            checkProbeCalled = true;
            return true;
          },
        );

        final result = await networkInfo.isConnected;
        expect(result, isTrue);
        expect(checkProbeCalled, isTrue);
        networkInfo.dispose();
      },
    );

    test(
      'isConnected returns false if active probe fails even with interface',
      () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.mobile]);

        final networkInfo = NetworkInfoImpl(
          connectivity: mockConnectivity,
          checkConnection: () async => false,
        );

        final result = await networkInfo.isConnected;
        expect(result, isFalse);
        networkInfo.dispose();
      },
    );

    test(
      'isConnected fast-path returns false without probe when offline is known',
      () async {
        var probeCount = 0;
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);

        final networkInfo = NetworkInfoImpl(
          connectivity: mockConnectivity,
          checkConnection: () async {
            probeCount++;
            return false;
          },
        );

        // Probe awal dijalankan (termasuk retry jika gagal pada interface)
        final firstResult = await networkInfo.isConnected;
        expect(firstResult, isFalse);
        expect(probeCount, 2);

        // Panggilan berikutnya menggunakan fast-path seketika tanpa probe
        final secondResult = await networkInfo.isConnected;
        expect(secondResult, isFalse);
        expect(probeCount, 2);

        networkInfo.dispose();
      },
    );

    test(
      'onConnectivityChanged emits updates upon OS interface changes',
      () async {
        var probeResult = true;
        final networkInfo = NetworkInfoImpl(
          connectivity: mockConnectivity,
          checkConnection: () async => probeResult,
        );

        final emittedStates = <bool>[];
        final subscription = networkInfo.onConnectivityChanged.listen(
          emittedStates.add,
        );

        // Simulasikan interface OS mati (offline)
        connectivityStreamController.add([ConnectivityResult.none]);
        await pumpEventQueue();
        expect(emittedStates, [false]);

        // Simulasikan interface OS aktif kembali (online)
        probeResult = true;
        connectivityStreamController.add([ConnectivityResult.wifi]);
        await pumpEventQueue();
        expect(emittedStates, [false, true]);

        // Perubahan yang sama tidak memancarkan duplicate state
        connectivityStreamController.add([ConnectivityResult.wifi]);
        await pumpEventQueue();
        expect(emittedStates, [false, true]);

        await subscription.cancel();
        networkInfo.dispose();
      },
    );

    test(
      'handover retry prevents false offline if probe recovers on second try',
      () async {
        var callCount = 0;
        final networkInfo = NetworkInfoImpl(
          connectivity: mockConnectivity,
          retryDelay: const Duration(milliseconds: 10),
          checkConnection: () async {
            callCount++;
            // Panggilan pertama (transient glitch saat handover) gagal,
            // panggilan retry berhasil
            return callCount > 1;
          },
        );

        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.mobile]);

        final emittedStates = <bool>[];
        final subscription = networkInfo.onConnectivityChanged.listen(
          emittedStates.add,
        );

        // Simulasikan pergantian interface OS ke Mobile
        connectivityStreamController.add([ConnectivityResult.mobile]);
        await Future<void>.delayed(const Duration(milliseconds: 25));

        // Karena retry berhasil, tidak ada state false yang dipancarkan
        expect(emittedStates, [true]);
        expect(callCount, 2);

        await subscription.cancel();
        networkInfo.dispose();
      },
    );

    test(
      'checkReachability emits false when both initial and retry probes fail',
      () async {
        final networkInfo = NetworkInfoImpl(
          connectivity: mockConnectivity,
          retryDelay: const Duration(milliseconds: 5),
          checkConnection: () async => false,
        );

        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);

        final result = await networkInfo.checkReachability();
        expect(result, isFalse);
        networkInfo.dispose();
      },
    );

    test(
      'checkConnectivity deduplicates concurrent in-flight probes',
      () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);

        var activeProbes = 0;
        final networkInfo = NetworkInfoImpl(
          connectivity: mockConnectivity,
          checkConnection: () async {
            activeProbes++;
            await Future<void>.delayed(const Duration(milliseconds: 20));
            return true;
          },
        );

        // Panggil checkConnectivity serentak 3 kali
        final results = await Future.wait([
          networkInfo.checkConnectivity(),
          networkInfo.checkConnectivity(),
          networkInfo.checkConnectivity(),
        ]);

        expect(results, [true, true, true]);
        expect(activeProbes, 1);
        networkInfo.dispose();
      },
    );

    test('isConnected re-probes after offlineCacheTtl expires and detects '
        'recovery', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      var isActuallyOnline = false;
      var probeCount = 0;
      final networkInfo = NetworkInfoImpl(
        connectivity: mockConnectivity,
        retryDelay: Duration.zero,
        offlineCacheTtl: const Duration(milliseconds: 30),
        checkConnection: () async {
          probeCount++;
          return isActuallyOnline;
        },
      );

      // Panggilan 1: Probe offline
      final initialStatus = await networkInfo.isConnected;
      expect(initialStatus, isFalse);
      expect(probeCount, 1);

      // Panggilan 2 (seketika): masih dalam jendela TTL, fast-path
      final cachedStatus = await networkInfo.isConnected;
      expect(cachedStatus, isFalse);
      expect(probeCount, 1);

      // Internet kembali pulih di access point yang sama
      isActuallyOnline = true;
      await Future<void>.delayed(const Duration(milliseconds: 40));

      // Panggilan 3: TTL sudah expire, harus probe ulang dan mendeteksi
      // status internet yang pulih
      final recoveredStatus = await networkInfo.isConnected;
      expect(recoveredStatus, isTrue);
      expect(probeCount, 2);

      networkInfo.dispose();
    });
  });
}
