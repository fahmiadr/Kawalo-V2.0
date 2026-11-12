import 'dart:typed_data';
import 'dart:ui';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/face/domain/entities/face_status.dart';
import 'package:kawalo_mobile/features/face/domain/face_frame.dart';
import 'package:kawalo_mobile/features/face/domain/face_quality.dart';
import 'package:kawalo_mobile/features/face/domain/repositories/face_repository.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/face_camera.dart';
import 'package:kawalo_mobile/features/face/presentation/cubit/face_registration_cubit.dart';
import 'package:kawalo_mobile/features/face/presentation/cubit/face_registration_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements FaceRepository {}

class _MockCamera extends Mock implements FaceCamera {}

const good = FaceFrame(
  imageSize: Size(480, 640),
  brightness: 120,
  faces: [DetectedFace(box: Rect.fromLTWH(140, 200, 200, 240))],
);
const far = FaceFrame(
  imageSize: Size(480, 640),
  faces: [DetectedFace(box: Rect.fromLTWH(200, 280, 80, 100))],
);

void main() {
  late _MockRepository repository;
  late _MockCamera camera;
  final photo = Uint8List.fromList([1, 2, 3]);

  setUpAll(() => registerFallbackValue(<Uint8List>[]));

  setUp(() {
    repository = _MockRepository();
    camera = _MockCamera();
    when(() => camera.start()).thenAnswer((_) async {});
    when(() => camera.frames).thenAnswer((_) => const Stream.empty());
    when(() => camera.capture()).thenAnswer((_) async => photo);
    when(() => camera.dispose()).thenAnswer((_) async {});
  });

  FaceRegistrationCubit build({bool replaceExisting = false}) =>
      FaceRegistrationCubit(
        repository: repository,
        cameraFactory: () => camera,
        replaceExisting: replaceExisting,
        photoTarget: 2,
        stableFrames: 1,
        cooldownFrames: 0,
      );

  void stubRegister(Either<Failure, FaceRegistration> result) {
    when(
      () => repository.register(
        any(),
        replaceExisting: any(named: 'replaceExisting'),
      ),
    ).thenAnswer((_) async => result);
  }

  Future<void> captureAll(FaceRegistrationCubit cubit) async {
    await cubit.begin();
    await cubit.onFrame(good);
    await cubit.onFrame(good);
  }

  blocTest<FaceRegistrationCubit, FaceRegistrationState>(
    'consent leads to the intro',
    build: build,
    act: (cubit) => cubit.acceptConsent(),
    expect: () => [const FaceRegistrationIntro()],
  );

  blocTest<FaceRegistrationCubit, FaceRegistrationState>(
    'shows the gate issue and does not shoot on a bad frame',
    build: build,
    act: (cubit) async {
      await cubit.begin();
      await cubit.onFrame(far);
    },
    expect: () => [
      const FaceRegistrationCapturing(captured: 0, total: 2),
      const FaceRegistrationCapturing(
        captured: 0,
        total: 2,
        issue: FaceIssue.tooFar,
      ),
    ],
    verify: (_) => verifyNever(() => camera.capture()),
  );

  blocTest<FaceRegistrationCubit, FaceRegistrationState>(
    'captures the target, releases the camera and uploads once',
    setUp: () => stubRegister(const Right(FaceRegistration(photoCount: 2))),
    build: () => build(replaceExisting: true),
    act: captureAll,
    expect: () => [
      const FaceRegistrationCapturing(captured: 0, total: 2),
      const FaceRegistrationCapturing(captured: 1, total: 2),
      const FaceRegistrationUploading(2),
      const FaceRegistrationSuccess(accepted: 2, submitted: 2),
    ],
    verify: (_) {
      verify(() => camera.dispose()).called(1);
      final photos =
          verify(
                () => repository.register(captureAny(), replaceExisting: true),
              ).captured.single
              as List<Uint8List>;
      expect(photos, [photo, photo]);
    },
  );

  blocTest<FaceRegistrationCubit, FaceRegistrationState>(
    'camera that cannot open becomes a fault',
    setUp: () => when(
      () => camera.start(),
    ).thenThrow(const FaceCameraException(FaceCameraFault.permissionDenied)),
    build: build,
    act: (cubit) => cubit.begin(),
    expect: () => [
      const FaceRegistrationCapturing(captured: 0, total: 2),
      const FaceRegistrationCameraFault(FaceCameraFault.permissionDenied),
    ],
  );

  blocTest<FaceRegistrationCubit, FaceRegistrationState>(
    'quality rejection asks for new photos',
    setUp: () => stubRegister(
      const Left(
        ServerFailure('Hanya 1 dari 2 foto lolos.', 422, 'FACE_QUALITY_LOW'),
      ),
    ),
    build: build,
    act: captureAll,
    skip: 3,
    expect: () => [
      const FaceRegistrationFailed(
        message: 'Hanya 1 dari 2 foto lolos.',
        canResubmit: false,
      ),
    ],
  );

  blocTest<FaceRegistrationCubit, FaceRegistrationState>(
    'duplicate face cannot be resubmitted',
    setUp: () => stubRegister(
      const Left(
        ServerFailure('Wajah sudah terdaftar.', 409, 'FACE_DUPLICATE'),
      ),
    ),
    build: build,
    act: captureAll,
    skip: 3,
    expect: () => [
      const FaceRegistrationFailed(
        message: 'Wajah sudah terdaftar.',
        canResubmit: false,
      ),
    ],
  );

  blocTest<FaceRegistrationCubit, FaceRegistrationState>(
    'network failure resends the same photos on retry',
    setUp: () {
      var calls = 0;
      when(
        () => repository.register(
          any(),
          replaceExisting: any(named: 'replaceExisting'),
        ),
      ).thenAnswer(
        (_) async => calls++ == 0
            ? const Left(NoInternetFailure())
            : const Right(FaceRegistration(photoCount: 2)),
      );
    },
    build: build,
    act: (cubit) async {
      await captureAll(cubit);
      await cubit.retry();
    },
    skip: 3,
    expect: () => [
      FaceRegistrationFailed(
        message: const NoInternetFailure().message,
        canResubmit: true,
      ),
      const FaceRegistrationUploading(2),
      const FaceRegistrationSuccess(accepted: 2, submitted: 2),
    ],
    verify: (_) {
      verify(
        () => repository.register(
          any(),
          replaceExisting: any(named: 'replaceExisting'),
        ),
      ).called(2);
      verify(() => camera.start()).called(1);
    },
  );

  blocTest<FaceRegistrationCubit, FaceRegistrationState>(
    'service unavailable has its own state',
    setUp: () => stubRegister(
      const Left(
        ServerFailure('Belum aktif.', 503, FaceErrorCodes.serviceUnavailable),
      ),
    ),
    build: build,
    act: captureAll,
    skip: 3,
    expect: () => [const FaceRegistrationServiceUnavailable()],
  );

  blocTest<FaceRegistrationCubit, FaceRegistrationState>(
    'already registered counts as done',
    setUp: () => stubRegister(
      const Left(
        ServerFailure('Sudah.', 409, FaceErrorCodes.alreadyRegistered),
      ),
    ),
    build: build,
    act: captureAll,
    skip: 3,
    expect: () => [const FaceRegistrationSuccess(accepted: null, submitted: 2)],
  );
}
