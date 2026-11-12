import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_check_result.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_slot.dart';
import 'package:kawalo_mobile/features/attendance/domain/repositories/attendance_check_repository.dart';
import 'package:kawalo_mobile/features/attendance/presentation/check/attendance_check_cubit.dart';
import 'package:kawalo_mobile/features/attendance/presentation/check/attendance_check_state.dart';
import 'package:kawalo_mobile/features/face/domain/entities/face_status.dart';
import 'package:kawalo_mobile/features/face/domain/face_frame.dart';
import 'package:kawalo_mobile/features/face/domain/face_quality.dart';
import 'package:kawalo_mobile/features/face/domain/repositories/face_repository.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/face_camera.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements AttendanceCheckRepository {}

class _MockFaceRepository extends Mock implements FaceRepository {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

class _MockLocation extends Mock implements LocationService {}

class _MockCamera extends Mock implements FaceCamera {}

FaceFrame _frame({double yaw = 0, double eyes = 0.9}) => FaceFrame(
  imageSize: const Size(480, 640),
  brightness: 120,
  faces: [
    DetectedFace(
      box: const Rect.fromLTWH(140, 200, 200, 240),
      yaw: yaw,
      pitch: 0,
      roll: 0,
      leftEyeOpen: eyes,
      rightEyeOpen: eyes,
    ),
  ],
);

final _position = Position(
  latitude: -6.2,
  longitude: 106.8,
  timestamp: DateTime(2026, 11, 12),
  accuracy: 12,
  altitude: 0,
  altitudeAccuracy: 1,
  heading: 0,
  headingAccuracy: 1,
  speed: 0,
  speedAccuracy: 1,
);

void main() {
  final now = DateTime(2026, 11, 12, 7, 5);
  final today = DateTime(2026, 11, 12);
  final slot = AttendanceSlot(
    date: today,
    shiftName: 'Shift Pagi',
    startTime: '07:00',
    endTime: '15:00',
    locationName: 'Pos Utama / Lobby',
  );
  final photo = Uint8List.fromList([9, 9, 9]);
  final result = AttendanceCheckResult(
    id: '42',
    isCheckIn: true,
    attendanceAt: DateTime(2026, 11, 12, 7, 5),
    status: AttendanceCheckStatus.late,
    lateMinutes: 5,
  );
  const usable = FaceStatus(available: true, registered: true);

  late _MockRepository repository;
  late _MockFaceRepository faceRepository;
  late _MockNetworkInfo networkInfo;
  late _MockLocation location;
  late _MockCamera camera;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(ManualAttendanceReason.faceFailed);
  });

  setUp(() {
    repository = _MockRepository();
    faceRepository = _MockFaceRepository();
    networkInfo = _MockNetworkInfo();
    location = _MockLocation();
    camera = _MockCamera();
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(
      () => faceRepository.getStatus(),
    ).thenAnswer((_) async => const Right(usable));
    when(
      () => repository.getSlots(any()),
    ).thenAnswer((_) async => Right([slot]));
    when(
      () => location.getCurrentPosition(),
    ).thenAnswer((_) async => LocationResult.success(_position));
    when(
      () => repository.issueNonce(),
    ).thenAnswer((_) async => const Right(AttendanceNonce('n')));
    when(() => camera.start()).thenAnswer((_) async {});
    when(() => camera.frames).thenAnswer((_) => const Stream.empty());
    when(() => camera.capture()).thenAnswer((_) async => photo);
    when(() => camera.dispose()).thenAnswer((_) async {});
  });

  AttendanceCheckCubit build({
    Duration stable = const Duration(milliseconds: 5),
  }) => AttendanceCheckCubit(
    repository: repository,
    faceRepository: faceRepository,
    networkInfo: networkInfo,
    cameraFactory: () => camera,
    location: location,
    clock: () => now,
    stableDuration: stable,
  );

  void stubSubmit(List<Either<Failure, AttendanceCheckResult>> answers) {
    var call = 0;
    when(
      () => repository.submit(
        photo: any(named: 'photo'),
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        nonce: any(named: 'nonce'),
      ),
    ).thenAnswer((_) async => answers[(call++).clamp(0, answers.length - 1)]);
  }

  /// A well-positioned face that stays put long enough triggers the photo
  /// and the submit.
  Future<void> scan(AttendanceCheckCubit cubit) async {
    await cubit.startScan();
    await cubit.onFrame(_frame());
    await Future<void>.delayed(const Duration(milliseconds: 60));
  }

  Future<void> loadAndScan(AttendanceCheckCubit cubit) async {
    await cubit.load();
    await scan(cubit);
  }

  final ready = AttendanceCheckReady(
    slot: slot,
    action: AttendanceAction.checkIn,
    accuracyMeters: 12,
  );

  group('load', () {
    blocTest<AttendanceCheckCubit, AttendanceCheckState>(
      'is ready to check in',
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [const AttendanceCheckLoading(), ready],
    );

    blocTest<AttendanceCheckCubit, AttendanceCheckState>(
      'is ready to check out after a check-in',
      setUp: () => when(() => repository.getSlots(any())).thenAnswer(
        (_) async => Right([
          AttendanceSlot(
            date: today,
            shiftName: 'Shift Pagi',
            startTime: '07:00',
            endTime: '15:00',
            checkin: '06:58:00',
          ),
        ]),
      ),
      build: build,
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(
        (cubit.state as AttendanceCheckReady).action,
        AttendanceAction.checkOut,
      ),
    );

    blocTest<AttendanceCheckCubit, AttendanceCheckState>(
      'is blocked offline without calling the server',
      setUp: () =>
          when(() => networkInfo.isConnected).thenAnswer((_) async => false),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const AttendanceCheckLoading(),
        const AttendanceCheckOffline(),
      ],
      verify: (_) => verifyNever(() => faceRepository.getStatus()),
    );

    final cases = <String, (Either<Failure, FaceStatus>, AttendanceCheckState)>{
      'no internet on the status call': (
        const Left(NoInternetFailure()),
        const AttendanceCheckOffline(),
      ),
      'a server error': (
        const Left(ServerFailure('Gagal.', 500)),
        const AttendanceCheckLoadFailed('Gagal.'),
      ),
      'FACE_SERVICE_UNAVAILABLE': (
        const Left(ServerFailure('x', 503, 'FACE_SERVICE_UNAVAILABLE')),
        const AttendanceCheckServiceUnavailable(),
      ),
      'no face model (available false)': (
        const Right(FaceStatus(available: false, registered: true)),
        const AttendanceCheckServiceUnavailable(),
      ),
      'no registered face': (
        const Right(FaceStatus(available: true, registered: false)),
        const AttendanceCheckFaceNotRegistered(reregister: false),
      ),
      'a face of an older model': (
        const Right(
          FaceStatus(
            available: true,
            registered: true,
            needsReregistration: true,
          ),
        ),
        const AttendanceCheckFaceNotRegistered(reregister: true),
      ),
    };
    for (final MapEntry(key: name, value: (status, expected))
        in cases.entries) {
      blocTest<AttendanceCheckCubit, AttendanceCheckState>(
        'maps $name',
        setUp: () => when(
          () => faceRepository.getStatus(),
        ).thenAnswer((_) async => status),
        build: build,
        act: (cubit) => cubit.load(),
        expect: () => [const AttendanceCheckLoading(), expected],
      );
    }

    blocTest<AttendanceCheckCubit, AttendanceCheckState>(
      'reports a failed schedule call',
      setUp: () => when(() => repository.getSlots(any())).thenAnswer(
        (_) async => const Left(ServerFailure('Jadwal gagal.', 500)),
      ),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const AttendanceCheckLoading(),
        const AttendanceCheckLoadFailed('Jadwal gagal.'),
      ],
    );

    blocTest<AttendanceCheckCubit, AttendanceCheckState>(
      'has no schedule today',
      setUp: () => when(
        () => repository.getSlots(any()),
      ).thenAnswer((_) async => const Right([])),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const AttendanceCheckLoading(),
        AttendanceCheckNoSchedule(today),
      ],
    );

    blocTest<AttendanceCheckCubit, AttendanceCheckState>(
      'is completed after check-in and check-out',
      setUp: () => when(() => repository.getSlots(any())).thenAnswer(
        (_) async => Right([
          AttendanceSlot(
            date: today,
            shiftName: 'Shift Pagi',
            startTime: '07:00',
            endTime: '15:00',
            checkin: '06:58:00',
            checkout: '15:03:00',
          ),
        ]),
      ),
      build: build,
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state, isA<AttendanceCheckCompleted>()),
    );

    blocTest<AttendanceCheckCubit, AttendanceCheckState>(
      'needs the GPS',
      setUp: () => when(
        () => location.getCurrentPosition(),
      ).thenAnswer((_) async => const LocationResult.serviceDisabled()),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const AttendanceCheckLoading(),
        const AttendanceCheckLocationFailed(LocationResult.serviceDisabled()),
      ],
    );
  });

  group('scan', () {
    blocTest<AttendanceCheckCubit, AttendanceCheckState>(
      'photographs a steady face and records the attendance',
      setUp: () => stubSubmit([Right(result)]),
      build: build,
      act: loadAndScan,
      skip: 1,
      expect: () => [
        ready,
        AttendanceCheckScanning(slot: slot, action: AttendanceAction.checkIn),
        AttendanceCheckVerifying(slot: slot, action: AttendanceAction.checkIn),
        AttendanceCheckSuccess(result),
      ],
      verify: (_) {
        verify(
          () => repository.submit(
            photo: photo,
            latitude: -6.2,
            longitude: 106.8,
            nonce: 'n',
          ),
        ).called(1);
        verify(() => camera.capture()).called(1);
        verify(() => camera.dispose()).called(1);
      },
    );

    blocTest<AttendanceCheckCubit, AttendanceCheckState>(
      'shows the quality hint while the face is not well positioned',
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.startScan();
        await cubit.onFrame(_frame(yaw: 30));
        await cubit.onFrame(_frame(eyes: 0.1));
        await cubit.onFrame(_frame());
        await cubit.close();
      },
      skip: 3,
      expect: () => [
        AttendanceCheckScanning(
          slot: slot,
          action: AttendanceAction.checkIn,
          issue: FaceIssue.tilted,
        ),
        AttendanceCheckScanning(
          slot: slot,
          action: AttendanceAction.checkIn,
          issue: FaceIssue.eyesClosed,
        ),
        AttendanceCheckScanning(slot: slot, action: AttendanceAction.checkIn),
      ],
      verify: (_) => verifyNever(() => camera.capture()),
    );

    testWidgets(
      'waits for the stable moment and restarts it when the face moves',
      (tester) async {
        final cubit = build(stable: const Duration(seconds: 1));
        unawaited(cubit.load());
        await tester.pump();
        unawaited(cubit.startScan());
        await tester.pump();

        unawaited(cubit.onFrame(_frame()));
        await tester.pump(const Duration(milliseconds: 900));
        unawaited(cubit.onFrame(_frame(yaw: 30)));
        await tester.pump(const Duration(seconds: 2));
        verifyNever(() => camera.capture());

        unawaited(cubit.onFrame(_frame()));
        await tester.pump(const Duration(milliseconds: 900));
        verifyNever(() => camera.capture());
        await tester.pump(const Duration(milliseconds: 150));
        verify(() => camera.capture()).called(1);
        unawaited(cubit.close());
        await tester.pump();
      },
    );

    blocTest<AttendanceCheckCubit, AttendanceCheckState>(
      'turns a camera that cannot open into a fault',
      setUp: () => when(
        () => camera.start(),
      ).thenThrow(const FaceCameraException(FaceCameraFault.unavailable)),
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.startScan();
      },
      skip: 3,
      expect: () => [
        const AttendanceCheckCameraFault(FaceCameraFault.unavailable),
      ],
    );

    blocTest<AttendanceCheckCubit, AttendanceCheckState>(
      'stops when the fresh GPS fix fails before sending',
      setUp: () {
        var call = 0;
        when(() => location.getCurrentPosition()).thenAnswer(
          (_) async => call++ == 0
              ? LocationResult.success(_position)
              : const LocationResult.permissionDenied(),
        );
      },
      build: build,
      act: loadAndScan,
      verify: (cubit) {
        expect(
          cubit.state,
          const AttendanceCheckLocationFailed(
            LocationResult.permissionDenied(),
          ),
        );
        verifyNever(
          () => repository.submit(
            photo: any(named: 'photo'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            nonce: any(named: 'nonce'),
          ),
        );
      },
    );
  });

  group('submit failures', () {
    final cases = <String, (Failure, AttendanceCheckState)>{
      'FACE_SERVICE_UNAVAILABLE': (
        const ServerFailure('x', 503, 'FACE_SERVICE_UNAVAILABLE'),
        const AttendanceCheckServiceUnavailable(),
      ),
      'FACE_NOT_REGISTERED': (
        const ServerFailure('x', 409, 'FACE_NOT_REGISTERED'),
        const AttendanceCheckFaceNotRegistered(reregister: true),
      ),
      'FACE_QUALITY_LOW': (
        const ServerFailure('Foto terlalu gelap.', 422, 'FACE_QUALITY_LOW'),
        const AttendanceCheckRejected(
          title: 'Foto wajah kurang jelas',
          message: 'Foto terlalu gelap.',
        ),
      ),
      'ATTENDANCE_NO_SCHEDULE': (
        const ServerFailure('x', 404, 'ATTENDANCE_NO_SCHEDULE'),
        AttendanceCheckNoSchedule(today),
      ),
      'ATTENDANCE_ALREADY_COMPLETED': (
        const ServerFailure('x', 409, 'ATTENDANCE_ALREADY_COMPLETED'),
        const AttendanceCheckCompleted(null),
      ),
      'ATTENDANCE_OUT_OF_RADIUS': (
        const ServerFailure('Anda 240 m.', 403, 'ATTENDANCE_OUT_OF_RADIUS'),
        const AttendanceCheckOutOfRadius('Anda 240 m.'),
      ),
      'ATTENDANCE_NONCE_INVALID twice': (
        const ServerFailure('Sesi.', 400, 'ATTENDANCE_NONCE_INVALID'),
        const AttendanceCheckRejected(
          title: 'Sesi absensi kedaluwarsa',
          message: 'Sesi.',
        ),
      ),
      'a rate limit': (
        const ServerFailure('Terlalu banyak.', 429, 'RATE_LIMIT_EXCEEDED'),
        const AttendanceCheckSubmitFailed('Terlalu banyak.'),
      ),
      'no internet': (
        const NoInternetFailure(),
        AttendanceCheckSubmitFailed(const NoInternetFailure().message),
      ),
      'any other refusal': (
        const ServerFailure('Ditolak.', 400, 'VALIDATION_ERROR'),
        const AttendanceCheckRejected(
          title: 'Absensi gagal',
          message: 'Ditolak.',
        ),
      ),
    };
    for (final MapEntry(key: name, value: (failure, expected))
        in cases.entries) {
      blocTest<AttendanceCheckCubit, AttendanceCheckState>(
        'maps $name',
        setUp: () => stubSubmit([Left(failure)]),
        build: build,
        act: loadAndScan,
        verify: (cubit) => expect(cubit.state, expected),
      );
    }

    blocTest<AttendanceCheckCubit, AttendanceCheckState>(
      'retries an expired nonce once with a new one',
      setUp: () => stubSubmit([
        const Left(ServerFailure('Sesi.', 400, 'ATTENDANCE_NONCE_INVALID')),
        Right(result),
      ]),
      build: build,
      act: loadAndScan,
      verify: (cubit) {
        expect(cubit.state, AttendanceCheckSuccess(result));
        // One read for the failure tally when the scan opens, then one per submit.
        verify(() => repository.issueNonce()).called(3);
      },
    );

    blocTest<AttendanceCheckCubit, AttendanceCheckState>(
      'resends the same photo after a network failure',
      setUp: () => stubSubmit([const Left(NoInternetFailure()), Right(result)]),
      build: build,
      act: (cubit) async {
        await loadAndScan(cubit);
        await cubit.resubmit();
      },
      verify: (cubit) {
        expect(cubit.state, AttendanceCheckSuccess(result));
        verify(() => camera.capture()).called(1);
      },
    );

    blocTest<AttendanceCheckCubit, AttendanceCheckState>(
      'reports a failed nonce request',
      setUp: () => when(
        () => repository.issueNonce(),
      ).thenAnswer((_) async => const Left(NoInternetFailure())),
      build: build,
      act: loadAndScan,
      verify: (cubit) =>
          expect(cubit.state, isA<AttendanceCheckSubmitFailed>()),
    );
  });

  group('face mismatch and manual request', () {
    blocTest<AttendanceCheckCubit, AttendanceCheckState>(
      'uses the server count and availability',
      setUp: () => stubSubmit([
        const Left(
          FaceNotMatchFailure(
            'Tidak cocok.',
            failedAttempts: 3,
            manualRequestAvailable: true,
          ),
        ),
      ]),
      build: build,
      act: loadAndScan,
      verify: (cubit) => expect(
        cubit.state,
        const AttendanceCheckFaceNotMatch(
          message: 'Tidak cocok.',
          failedAttempts: 3,
          canRequestManual: true,
        ),
      ),
    );

    blocTest<AttendanceCheckCubit, AttendanceCheckState>(
      'counts locally when the server sends no count',
      setUp: () => stubSubmit([const Left(FaceNotMatchFailure('Tidak.'))]),
      build: build,
      act: (cubit) async {
        await loadAndScan(cubit);
        await scan(cubit);
        await scan(cubit);
      },
      verify: (cubit) {
        final state = cubit.state as AttendanceCheckFaceNotMatch;
        expect(state.failedAttempts, 3);
        expect(state.canRequestManual, isTrue);
      },
    );

    blocTest<AttendanceCheckCubit, AttendanceCheckState>(
      'sends a manual request with the last position',
      setUp: () {
        stubSubmit([
          const Left(
            FaceNotMatchFailure(
              'x',
              failedAttempts: 3,
              manualRequestAvailable: true,
            ),
          ),
        ]);
        when(
          () => repository.requestManual(
            reason: any(named: 'reason'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            note: any(named: 'note'),
          ),
        ).thenAnswer((_) async => const Right('mr-1'));
      },
      build: build,
      act: (cubit) async {
        await loadAndScan(cubit);
        await cubit.openManualRequest(ManualAttendanceReason.faceFailed);
        await cubit.sendManualRequest('Kamera buram');
      },
      skip: 5,
      expect: () => [
        const AttendanceCheckManualRequest(ManualAttendanceReason.faceFailed),
        const AttendanceCheckManualRequest(
          ManualAttendanceReason.faceFailed,
          sending: true,
        ),
        const AttendanceCheckManualSent(alreadyPending: false),
      ],
      verify: (_) => verify(
        () => repository.requestManual(
          reason: ManualAttendanceReason.faceFailed,
          latitude: -6.2,
          longitude: 106.8,
          note: 'Kamera buram',
        ),
      ).called(1),
    );

    group('manual request outcomes', () {
      void stubManual(Either<Failure, String> answer) => when(
        () => repository.requestManual(
          reason: any(named: 'reason'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => answer);

      Future<void> request(AttendanceCheckCubit cubit) async {
        await cubit.load();
        await cubit.openManualRequest(ManualAttendanceReason.cameraUnavailable);
        await cubit.sendManualRequest(null);
      }

      blocTest<AttendanceCheckCubit, AttendanceCheckState>(
        '409 means a request is already pending',
        setUp: () => stubManual(const Left(ServerFailure('Sudah ada.', 409))),
        build: build,
        act: request,
        verify: (cubit) => expect(
          cubit.state,
          const AttendanceCheckManualSent(alreadyPending: true),
        ),
      );

      blocTest<AttendanceCheckCubit, AttendanceCheckState>(
        '403 keeps the form with the server message',
        setUp: () => stubManual(const Left(ServerFailure('Belum boleh.', 403))),
        build: build,
        act: request,
        verify: (cubit) => expect(
          cubit.state,
          const AttendanceCheckManualRequest(
            ManualAttendanceReason.cameraUnavailable,
            error: 'Belum boleh.',
          ),
        ),
      );

      blocTest<AttendanceCheckCubit, AttendanceCheckState>(
        'cancel returns to the previous screen',
        build: build,
        act: (cubit) async {
          await cubit.load();
          await cubit.openManualRequest(
            ManualAttendanceReason.cameraUnavailable,
          );
          cubit.cancelManualRequest();
        },
        verify: (cubit) => expect(cubit.state, ready),
      );
    });
  });

  group('retrying is never capped', () {
    for (final failures in [1, 3, 5]) {
      test('a new scan starts after $failures failed matches', () async {
        stubSubmit([
          Left(
            FaceNotMatchFailure(
              'Tidak.',
              failedAttempts: failures,
              manualRequestAvailable: failures >= 3,
            ),
          ),
        ]);
        final cubit = build();
        addTearDown(cubit.close);
        await loadAndScan(cubit);

        final mismatch = cubit.state as AttendanceCheckFaceNotMatch;
        expect(mismatch.failedAttempts, failures);
        expect(mismatch.canRequestManual, failures >= 3);

        await cubit.startScan();
        final scanning = cubit.state as AttendanceCheckScanning;
        expect(scanning.canRequestManual, failures >= 3);
      });
    }

    test('five local mismatches still allow another scan', () async {
      stubSubmit([const Left(FaceNotMatchFailure('Tidak.'))]);
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load();
      for (var i = 0; i < 5; i++) {
        await scan(cubit);
        expect(cubit.state, isA<AttendanceCheckFaceNotMatch>());
      }
      await cubit.startScan();
      expect(cubit.state, isA<AttendanceCheckScanning>());
    });

    blocTest<AttendanceCheckCubit, AttendanceCheckState>(
      'a fresh session offers the report when the nonce says so',
      setUp: () => when(() => repository.issueNonce()).thenAnswer(
        (_) async => const Right(
          AttendanceNonce('n', failedAttempts: 4, manualRequestAvailable: true),
        ),
      ),
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.startScan();
        await Future<void>.delayed(Duration.zero);
      },
      skip: 3,
      expect: () => [
        AttendanceCheckScanning(
          slot: slot,
          action: AttendanceAction.checkIn,
          canRequestManual: true,
        ),
      ],
    );

    blocTest<AttendanceCheckCubit, AttendanceCheckState>(
      'reporting from the camera screen and cancelling resumes the scan',
      setUp: () => when(() => repository.issueNonce()).thenAnswer(
        (_) async =>
            const Right(AttendanceNonce('n', manualRequestAvailable: true)),
      ),
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.startScan();
        await Future<void>.delayed(Duration.zero);
        await cubit.openManualRequest(ManualAttendanceReason.faceFailed);
        expect(cubit.state, isA<AttendanceCheckManualRequest>());
        cubit.cancelManualRequest();
        await Future<void>.delayed(Duration.zero);
      },
      verify: (cubit) {
        expect(cubit.state, isA<AttendanceCheckScanning>());
        verify(() => camera.start()).called(2);
        verify(() => camera.dispose()).called(greaterThanOrEqualTo(1));
      },
    );
  });

  test('canRequestManualAttendance prefers the server', () {
    expect(canRequestManualAttendance(localFailures: 2), isFalse);
    expect(canRequestManualAttendance(localFailures: 3), isTrue);
    expect(
      canRequestManualAttendance(localFailures: 0, serverFailures: 3),
      isTrue,
    );
    expect(
      canRequestManualAttendance(
        localFailures: 5,
        serverFailures: 5,
        serverAvailable: false,
      ),
      isFalse,
    );
  });
}
