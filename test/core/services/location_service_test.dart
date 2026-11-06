import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kawalo_mobile/core/config/env_config.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:mocktail/mocktail.dart';

class MockGeolocatorPlatform extends Mock implements GeolocatorPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyPosition = Position(
    longitude: 106.8456,
    latitude: -6.2088,
    timestamp: DateTime(2026, 10, 2),
    accuracy: 5,
    altitude: 10,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 1,
  );

  final dummyMockedPosition = Position(
    longitude: 106.8456,
    latitude: -6.2088,
    timestamp: DateTime(2026, 10, 2),
    accuracy: 5,
    altitude: 10,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 1,
    isMocked: true,
  );

  group('LocationStatus Domain Extension Tests', () {
    test('isSuccess and isFailure evaluate correctly', () {
      expect(LocationStatus.success.isSuccess, isTrue);
      expect(LocationStatus.success.isFailure, isFalse);

      expect(LocationStatus.serviceDisabled.isSuccess, isFalse);
      expect(LocationStatus.serviceDisabled.isFailure, isTrue);
    });

    test('isPermissionRelated returns true only for permission statuses', () {
      expect(LocationStatus.permissionDenied.isPermissionRelated, isTrue);
      expect(
        LocationStatus.permissionDeniedForever.isPermissionRelated,
        isTrue,
      );
      expect(
        LocationStatus.preciseLocationRequired.isPermissionRelated,
        isTrue,
      );
      expect(LocationStatus.serviceDisabled.isPermissionRelated, isFalse);
      expect(LocationStatus.success.isPermissionRelated, isFalse);
      expect(LocationStatus.timeout.isPermissionRelated, isFalse);
    });
  });

  group('LocationResult Value Object Tests', () {
    test('success factory creates valid safe result with coordinates record',
        () {
      final result = LocationResult.success(dummyPosition);

      expect(result.status, equals(LocationStatus.success));
      expect(result.position, equals(dummyPosition));
      expect(result.isMocked, isFalse);
      expect(result.errorMessage, isNull);
      expect(result.isSafe, isTrue);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);

      expect(result.coordinates, isNotNull);
      final (lat, lng) = result.coordinates!;
      expect(lat, equals(-6.2088));
      expect(lng, equals(106.8456));
    });

    test('serviceDisabled factory creates expected status with null coords',
        () {
      const result = LocationResult.serviceDisabled();

      expect(result.status, equals(LocationStatus.serviceDisabled));
      expect(result.position, isNull);
      expect(result.coordinates, isNull);
      expect(result.isSafe, isFalse);
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('Layanan lokasi'));
    });

    test('permissionDenied factory creates expected status', () {
      const result = LocationResult.permissionDenied();

      expect(result.status, equals(LocationStatus.permissionDenied));
      expect(result.isSafe, isFalse);
      expect(
        result.errorMessage,
        contains('Izin akses lokasi belum diberikan'),
      );
    });

    test('permissionDeniedForever factory creates expected status', () {
      const result = LocationResult.permissionDeniedForever();

      expect(result.status, equals(LocationStatus.permissionDeniedForever));
      expect(result.isSafe, isFalse);
      expect(result.errorMessage, contains('dinonaktifkan'));
    });

    test('preciseLocationRequired factory creates expected status', () {
      const result = LocationResult.preciseLocationRequired();

      expect(result.status, equals(LocationStatus.preciseLocationRequired));
      expect(result.isSafe, isFalse);
      expect(result.errorMessage, contains('presisi'));
    });

    test('mockDetected factory creates expected status', () {
      final result = LocationResult.mockDetected(position: dummyMockedPosition);

      expect(result.status, equals(LocationStatus.mockLocationDetected));
      expect(result.position, equals(dummyMockedPosition));
      expect(result.isMocked, isTrue);
      expect(result.isSafe, isFalse);
      expect(result.errorMessage, contains('lokasi tiruan'));
    });

    test('timeout factory creates expected status', () {
      const result = LocationResult.timeout();

      expect(result.status, equals(LocationStatus.timeout));
      expect(result.isSafe, isFalse);
      expect(result.errorMessage, contains('Waktu pencarian lokasi'));
    });

    test('error factory creates expected status', () {
      const result = LocationResult.error('Internal hardware failure');

      expect(result.status, equals(LocationStatus.unknownError));
      expect(result.isSafe, isFalse);
      expect(result.errorMessage, equals('Internal hardware failure'));
    });

    test('supports value equality through Equatable', () {
      final resultA = LocationResult.success(dummyPosition);
      final resultB = LocationResult.success(dummyPosition);

      expect(resultA, equals(resultB));
      expect(resultA.props, equals(resultB.props));
    });

    test('copyWith updates properties or retains values via sentinel', () {
      final initial = LocationResult.success(dummyPosition);

      final updated = initial.copyWith(
        status: LocationStatus.mockLocationDetected,
        isMocked: true,
      );
      expect(updated.status, equals(LocationStatus.mockLocationDetected));
      expect(updated.position, equals(dummyPosition));
      expect(updated.isMocked, isTrue);

      final clearedPosition = updated.copyWith(position: null);
      expect(clearedPosition.position, isNull);
      expect(
        clearedPosition.status,
        equals(LocationStatus.mockLocationDetected),
      );
    });
  });

  group('DefaultLocationService Pure DI Tests', () {
    late MockGeolocatorPlatform mockPlatform;
    late LocationService service;

    setUp(() {
      mockPlatform = MockGeolocatorPlatform();
      when(mockPlatform.getLocationAccuracy)
          .thenAnswer((_) async => LocationAccuracyStatus.precise);
      service = DefaultLocationService(geolocatorPlatform: mockPlatform);
    });

    test('returns serviceDisabled when device GPS is disabled', () async {
      when(mockPlatform.isLocationServiceEnabled)
          .thenAnswer((_) async => false);

      final result = await service.getCurrentPosition();

      expect(result.status, equals(LocationStatus.serviceDisabled));
      expect(result.isSafe, isFalse);
      verify(mockPlatform.isLocationServiceEnabled).called(1);
    });

    test('returns permissionDenied when user denies permission', () async {
      when(mockPlatform.isLocationServiceEnabled)
          .thenAnswer((_) async => true);
      when(mockPlatform.checkPermission)
          .thenAnswer((_) async => LocationPermission.denied);
      when(mockPlatform.requestPermission)
          .thenAnswer((_) async => LocationPermission.denied);

      final result = await service.getCurrentPosition();

      expect(result.status, equals(LocationStatus.permissionDenied));
      expect(result.isSafe, isFalse);
      verify(mockPlatform.requestPermission).called(1);
    });

    test('returns permissionDeniedForever when permission is deniedForever',
        () async {
      when(mockPlatform.isLocationServiceEnabled)
          .thenAnswer((_) async => true);
      when(mockPlatform.checkPermission)
          .thenAnswer((_) async => LocationPermission.deniedForever);

      final result = await service.getCurrentPosition();

      expect(result.status, equals(LocationStatus.permissionDeniedForever));
      expect(result.isSafe, isFalse);
      verifyNever(mockPlatform.requestPermission);
    });

    test('returns success when valid real location is obtained', () async {
      when(mockPlatform.isLocationServiceEnabled)
          .thenAnswer((_) async => true);
      when(mockPlatform.checkPermission)
          .thenAnswer((_) async => LocationPermission.whileInUse);
      when(
        () => mockPlatform.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenAnswer((_) async => dummyPosition);

      final result = await service.getCurrentPosition();

      expect(result.status, equals(LocationStatus.success));
      expect(result.position, equals(dummyPosition));
      expect(result.isSafe, isTrue);
    });

    test('returns mockLocationDetected when isMocked is true and enforced',
        () async {
      when(mockPlatform.isLocationServiceEnabled)
          .thenAnswer((_) async => true);
      when(mockPlatform.checkPermission)
          .thenAnswer((_) async => LocationPermission.always);
      when(
        () => mockPlatform.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenAnswer((_) async => dummyMockedPosition);

      final result = await service.getCurrentPosition(
        enforceMockDetection: true,
      );

      expect(result.status, equals(LocationStatus.mockLocationDetected));
      expect(result.isMocked, isTrue);
      expect(result.isSafe, isFalse);
    });

    test('returns timeout when position request exceeds time limit', () async {
      when(mockPlatform.isLocationServiceEnabled)
          .thenAnswer((_) async => true);
      when(mockPlatform.checkPermission)
          .thenAnswer((_) async => LocationPermission.always);
      when(
        () => mockPlatform.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenThrow(TimeoutException('GPS timeout'));

      final result = await service.getCurrentPosition();

      expect(result.status, equals(LocationStatus.timeout));
      expect(result.isSafe, isFalse);
    });

    test('handles LocationServiceDisabledException gracefully', () async {
      when(mockPlatform.isLocationServiceEnabled)
          .thenAnswer((_) async => true);
      when(mockPlatform.checkPermission)
          .thenAnswer((_) async => LocationPermission.always);
      when(
        () => mockPlatform.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenThrow(const LocationServiceDisabledException());

      final result = await service.getCurrentPosition();

      expect(result.status, equals(LocationStatus.serviceDisabled));
      expect(result.isSafe, isFalse);
    });

    test('handles PermissionDeniedException gracefully', () async {
      when(mockPlatform.isLocationServiceEnabled)
          .thenAnswer((_) async => true);
      when(mockPlatform.checkPermission)
          .thenAnswer((_) async => LocationPermission.always);
      when(
        () => mockPlatform.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenThrow(const PermissionDeniedException('denied'));

      final result = await service.getCurrentPosition();

      expect(result.status, equals(LocationStatus.permissionDenied));
      expect(result.isSafe, isFalse);
    });

    test('returns unknownError when unexpected exception is thrown', () async {
      when(mockPlatform.isLocationServiceEnabled)
          .thenAnswer((_) async => true);
      when(mockPlatform.checkPermission)
          .thenThrow(Exception('Native bridge failure'));

      final result = await service.getCurrentPosition();

      expect(result.status, equals(LocationStatus.unknownError));
      expect(result.errorMessage, contains('Native bridge failure'));
      expect(result.isSafe, isFalse);
    });

    test('handles unableToDetermine permission gracefully', () async {
      when(mockPlatform.isLocationServiceEnabled)
          .thenAnswer((_) async => true);
      when(mockPlatform.checkPermission)
          .thenAnswer((_) async => LocationPermission.unableToDetermine);

      final result = await service.getCurrentPosition();

      expect(result.status, equals(LocationStatus.unknownError));
      expect(result.errorMessage, contains('tidak dapat ditentukan'));
    });

    test('handles requestPermission unableToDetermine gracefully', () async {
      when(mockPlatform.isLocationServiceEnabled)
          .thenAnswer((_) async => true);
      when(mockPlatform.checkPermission)
          .thenAnswer((_) async => LocationPermission.denied);
      when(mockPlatform.requestPermission)
          .thenAnswer((_) async => LocationPermission.unableToDetermine);

      final result = await service.getCurrentPosition();

      expect(result.status, equals(LocationStatus.unknownError));
      expect(result.errorMessage, contains('tidak dapat ditentukan'));
    });

    test('getLastKnownPosition returns cached position or null on failure',
        () async {
      when(mockPlatform.getLastKnownPosition)
          .thenAnswer((_) async => dummyPosition);

      final position = await service.getLastKnownPosition();
      expect(position, equals(dummyPosition));

      when(mockPlatform.getLastKnownPosition)
          .thenThrow(Exception('Failed to read cache'));
      final failedPosition = await service.getLastKnownPosition();
      expect(failedPosition, isNull);
    });

    test('distanceBetween delegates calculation to platform', () {
      when(
        () => mockPlatform.distanceBetween(
          -6.2088,
          106.8456,
          -6.2090,
          106.8458,
        ),
      ).thenReturn(31.5);

      final distance = service.distanceBetween(
        -6.2088,
        106.8456,
        -6.2090,
        106.8458,
      );

      expect(distance, equals(31.5));
    });

    test(
      'returns preciseLocationRequired when accuracy is reduced and '
      'upgrade fails',
      () async {
        when(mockPlatform.isLocationServiceEnabled)
            .thenAnswer((_) async => true);
        when(mockPlatform.checkPermission)
            .thenAnswer((_) async => LocationPermission.whileInUse);
        when(mockPlatform.getLocationAccuracy)
            .thenAnswer((_) async => LocationAccuracyStatus.reduced);
        when(mockPlatform.requestPermission)
            .thenAnswer((_) async => LocationPermission.whileInUse);

        final result = await service.getCurrentPosition();

        expect(result.status, equals(LocationStatus.preciseLocationRequired));
        expect(result.isSafe, isFalse);
        verify(mockPlatform.requestPermission).called(1);
      },
    );

    test(
      'returns success when initial accuracy is reduced but upgraded '
      'to precise',
      () async {
        when(mockPlatform.isLocationServiceEnabled)
            .thenAnswer((_) async => true);
        when(mockPlatform.checkPermission)
            .thenAnswer((_) async => LocationPermission.whileInUse);
        var accuracyCallCount = 0;
        when(mockPlatform.getLocationAccuracy).thenAnswer((_) async {
          accuracyCallCount++;
          return accuracyCallCount == 1
              ? LocationAccuracyStatus.reduced
              : LocationAccuracyStatus.precise;
        });
        when(mockPlatform.requestPermission)
            .thenAnswer((_) async => LocationPermission.whileInUse);
        when(
          () => mockPlatform.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          ),
        ).thenAnswer((_) async => dummyPosition);

        final result = await service.getCurrentPosition();

        expect(result.status, equals(LocationStatus.success));
        expect(result.position, equals(dummyPosition));
        expect(result.isSafe, isTrue);
      },
    );

    test(
      'proceeds safely when getLocationAccuracy throws an exception',
      () async {
        when(mockPlatform.isLocationServiceEnabled)
            .thenAnswer((_) async => true);
        when(mockPlatform.checkPermission)
            .thenAnswer((_) async => LocationPermission.whileInUse);
        when(mockPlatform.getLocationAccuracy)
            .thenThrow(UnsupportedError('Platform not supported'));
        when(
          () => mockPlatform.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          ),
        ).thenAnswer((_) async => dummyPosition);

        final result = await service.getCurrentPosition();

        expect(result.status, equals(LocationStatus.success));
        expect(result.position, equals(dummyPosition));
      },
    );

    test('getCurrentPosition safely handles uninitialized EnvConfig', () async {
      EnvConfig.resetForTesting();
      expect(EnvConfig.isInitialized, isFalse);

      when(mockPlatform.isLocationServiceEnabled)
          .thenAnswer((_) async => true);
      when(mockPlatform.checkPermission)
          .thenAnswer((_) async => LocationPermission.always);
      when(
        () => mockPlatform.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenAnswer((_) async => dummyPosition);

      final result = await service.getCurrentPosition();

      expect(result.status, equals(LocationStatus.success));
      expect(result.position, equals(dummyPosition));
    });

    test('LocationService.instance provides default singleton', () {
      expect(LocationService.instance, isA<DefaultLocationService>());
    });
  });
}
