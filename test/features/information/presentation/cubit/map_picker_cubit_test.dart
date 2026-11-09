import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/map_picker_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/map_picker/map_picker_overlay_state.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:mocktail/mocktail.dart';

class _MockGeocode extends Mock implements ReverseGeocodeService {}

class _MockLocation extends Mock implements LocationService {}

Position _position(double lat, double lng) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: DateTime(2026),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  late _MockGeocode geocode;
  late _MockLocation location;
  late int geocodeStarts;
  const target = LatLng(-6.2, 106.8);

  setUpAll(() {
    registerFallbackValue(const LatLng(0, 0));
  });

  setUp(() {
    geocode = _MockGeocode();
    location = _MockLocation();
    geocodeStarts = 0;
  });

  MapPickerCubit build({
    MapPickerOverlayState initial = const MapPickerOverlayState(),
    Future<LocationResult> Function()? locationProvider,
    Future<Position?> Function()? lastKnown,
  }) => MapPickerCubit(
    geocode,
    location,
    initialState: initial,
    locationProvider: locationProvider,
    lastKnownLocationProvider: lastKnown,
    onGeocodeStart: () => geocodeStarts++,
  );

  void stubGeocode(Future<ReverseGeocodeResult> Function(Invocation) answer) {
    when(
      () => geocode.reverseGeocode(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer(answer);
  }

  VerificationResult verifyGeocode() => verify(
    () => geocode.reverseGeocode(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
      cancelToken: any(named: 'cancelToken'),
    ),
  );

  void verifyNoGeocode() => verifyNever(
    () => geocode.reverseGeocode(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
      cancelToken: any(named: 'cancelToken'),
    ),
  );

  group('geocoding', () {
    testWidgets('debounces 650ms from the last schedule', (tester) async {
      stubGeocode(
        (_) async => const ReverseGeocodeResult.success(
          latitude: 1,
          longitude: 1,
          address: 'Jl. Merdeka',
        ),
      );
      final cubit = build();
      final states = <MapPickerOverlayState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.scheduleGeocode(target);
      await tester.pump(const Duration(milliseconds: 400));
      cubit.scheduleGeocode(target);
      await tester.pump(const Duration(milliseconds: 649));
      verifyNoGeocode();
      expect(states, isEmpty);

      await tester.pump(const Duration(milliseconds: 1));
      expect(geocodeStarts, 1);
      await tester.pump();
      verifyGeocode().called(1);

      expect(states, [
        const MapPickerOverlayState(isResolvingAddress: true),
        const MapPickerOverlayState(resolvedAddress: 'Jl. Merdeka'),
      ]);
      unawaited(sub.cancel());
      await cubit.close();
    });

    testWidgets('immediate geocode starts without delay', (tester) async {
      stubGeocode(
        (_) async =>
            const ReverseGeocodeResult.noResult(latitude: 1, longitude: 1),
      );
      final cubit = build()..scheduleGeocode(target, immediate: true);
      expect(cubit.state.isResolvingAddress, isTrue);
      expect(geocodeStarts, 1);
      await tester.pump();

      expect(cubit.state.isResolvingAddress, isFalse);
      expect(cubit.state.hasGeocodeError, isTrue);
      expect(cubit.state.resolvedAddress, isNull);
      await cubit.close();
    });

    testWidgets('blank address and thrown errors flag geocode error', (
      tester,
    ) async {
      stubGeocode(
        (_) async => const ReverseGeocodeResult.success(
          latitude: 1,
          longitude: 1,
          address: '   ',
        ),
      );
      final cubit = build(
        initial: const MapPickerOverlayState(resolvedAddress: 'lama'),
      )..scheduleGeocode(target, immediate: true);
      await tester.pump();
      expect(cubit.state.hasGeocodeError, isTrue);
      expect(cubit.state.resolvedAddress, isNull);

      stubGeocode((_) async => throw Exception('x'));
      cubit.scheduleGeocode(target, immediate: true);
      await tester.pump();
      expect(cubit.state.hasGeocodeError, isTrue);
      expect(cubit.state.isResolvingAddress, isFalse);
      await cubit.close();
    });

    testWidgets('newer request cancels the older one and wins', (tester) async {
      final completers = <Completer<ReverseGeocodeResult>>[];
      final tokens = <AppCancellationToken?>[];
      stubGeocode((invocation) {
        tokens.add(
          invocation.namedArguments[#cancelToken] as AppCancellationToken?,
        );
        final completer = Completer<ReverseGeocodeResult>();
        completers.add(completer);
        return completer.future;
      });
      final cubit = build()
        ..scheduleGeocode(target, immediate: true)
        ..scheduleGeocode(target, immediate: true);
      expect(tokens.first!.isCancelled, isTrue);
      expect(tokens.last!.isCancelled, isFalse);

      completers.last.complete(
        const ReverseGeocodeResult.success(
          latitude: 1,
          longitude: 1,
          address: 'Baru',
        ),
      );
      await tester.pump();
      completers.first.complete(
        const ReverseGeocodeResult.success(
          latitude: 1,
          longitude: 1,
          address: 'Lama',
        ),
      );
      await tester.pump();

      expect(cubit.state.resolvedAddress, 'Baru');
      await cubit.close();
    });

    testWidgets('close cancels pending debounce', (tester) async {
      final cubit = build()..scheduleGeocode(target);
      await cubit.close();
      await tester.pump(const Duration(seconds: 1));
      verifyNoGeocode();
    });

    testWidgets('retry is ignored while resolving or locating', (tester) async {
      final cubit = build(
        initial: const MapPickerOverlayState(isLocatingUser: true),
      )..retryGeocode(target);
      expect(geocodeStarts, 0);
      await cubit.close();
    });

    test(
      'handleUserGesture marks interaction and clears geocode error',
      () async {
        stubGeocode((_) => Completer<ReverseGeocodeResult>().future);
        final cubit = build(
          initial: const MapPickerOverlayState(hasGeocodeError: true),
        )..handleUserGesture(target);
        expect(cubit.state.hasUserInteracted, isTrue);
        expect(cubit.state.hasGeocodeError, isFalse);
        await cubit.close();
      },
    );
  });

  group('GPS', () {
    testWidgets('success runs callbacks in order, confirms fix and geocodes', (
      tester,
    ) async {
      stubGeocode(
        (_) async => const ReverseGeocodeResult.success(
          latitude: 1,
          longitude: 1,
          address: 'Jl. GPS',
        ),
      );
      final cubit = build(
        locationProvider: () async =>
            LocationResult.success(_position(-7.25, 112.76)),
      );
      final order = <String>[];
      LatLng? located;

      await cubit.goToCurrentLocation(
        onFixFound: () => order.add('fix'),
        onLocated: (c) {
          order.add('located');
          located = c;
        },
        onFailure: (_) => order.add('failure'),
      );
      await tester.pump();

      expect(order, ['fix', 'located']);
      expect(located, const LatLng(-7.25, 112.76));
      expect(cubit.state.isLocatingUser, isFalse);
      expect(cubit.state.hasConfirmedFix, isTrue);
      expect(cubit.state.resolvedAddress, 'Jl. GPS');
      await cubit.close();
    });

    testWidgets('auto-recovery keeps manual choice after user interaction', (
      tester,
    ) async {
      final cubit = build(
        initial: const MapPickerOverlayState(hasUserInteracted: true),
        locationProvider: () async =>
            LocationResult.success(_position(-7.25, 112.76)),
      );
      var fixFound = false;
      var located = false;

      await cubit.goToCurrentLocation(
        isAutoRecovery: true,
        onFixFound: () => fixFound = true,
        onLocated: (_) => located = true,
        onFailure: (_) {},
      );

      expect(fixFound, isTrue);
      expect(located, isFalse);
      expect(cubit.state.hasConfirmedFix, isFalse);
      expect(cubit.state.isLocatingUser, isFalse);
      await cubit.close();
    });

    testWidgets('failure result and thrown error go to onFailure', (
      tester,
    ) async {
      var shouldThrow = false;
      final cubit = build(
        locationProvider: () async => shouldThrow
            ? throw Exception('gps')
            : const LocationResult.serviceDisabled(),
      );
      final failures = <LocationResult>[];

      await cubit.goToCurrentLocation(
        onFixFound: () {},
        onLocated: (_) {},
        onFailure: failures.add,
      );
      shouldThrow = true;
      await cubit.goToCurrentLocation(
        onFixFound: () {},
        onLocated: (_) {},
        onFailure: failures.add,
      );

      expect(failures.first.status, LocationStatus.serviceDisabled);
      expect(
        failures.last.errorMessage,
        'Gagal mendeteksi lokasi GPS perangkat Anda.',
      );
      expect(cubit.state.isLocatingUser, isFalse);
      await cubit.close();
    });

    testWidgets('second request while locating is ignored', (tester) async {
      final completer = Completer<LocationResult>();
      var calls = 0;
      final cubit = build(
        locationProvider: () {
          calls++;
          return completer.future;
        },
      );

      final first = cubit.goToCurrentLocation(
        onFixFound: () {},
        onLocated: (_) {},
        onFailure: (_) {},
      );
      await cubit.goToCurrentLocation(
        onFixFound: () {},
        onLocated: (_) {},
        onFailure: (_) {},
      );
      expect(calls, 1);
      expect(cubit.state.isLocatingUser, isTrue);

      completer.complete(const LocationResult.serviceDisabled());
      await first;
      expect(cubit.state.isLocatingUser, isFalse);
      await cubit.close();
    });

    test('viewport hint is dropped once a fix exists', () async {
      final position = _position(-7.8, 110.3);
      final fresh = build(lastKnown: () async => position);
      expect(await fresh.fetchViewportHint(), position);

      final fixed = build(
        initial: const MapPickerOverlayState(hasConfirmedFix: true),
        lastKnown: () async => position,
      );
      expect(await fixed.fetchViewportHint(), isNull);

      final failing = build(lastKnown: () async => throw Exception('x'));
      expect(await failing.fetchViewportHint(), isNull);
      await fresh.close();
      await fixed.close();
      await failing.close();
    });
  });
}
