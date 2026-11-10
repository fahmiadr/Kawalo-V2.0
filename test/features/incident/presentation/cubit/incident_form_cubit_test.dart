import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/create_incident/create_incident_params.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/create_incident/create_incident_usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_category.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_form_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_form_state.dart';
import 'package:kawalo_mobile/features/incident/presentation/models/incident_media_item.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateIncidentUseCase extends Mock implements CreateIncidentUseCase {}

class FakeCreateIncidentParams extends Fake implements CreateIncidentParams {}

class MockUploadRepository extends Mock implements UploadRepository {}

class FakeAppMediaFile extends Fake implements AppMediaFile {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCreateIncidentParams());
    registerFallbackValue(FakeAppMediaFile());
  });

  late MockCreateIncidentUseCase mockCreateIncidentUseCase;
  late MockUploadRepository mockUpload;
  late IncidentFormCubit cubit;

  setUp(() {
    mockCreateIncidentUseCase = MockCreateIncidentUseCase();
    mockUpload = MockUploadRepository();
    cubit = IncidentFormCubit(
      createIncidentUseCase: mockCreateIncidentUseCase,
      uploadRepository: mockUpload,
    );
  });

  tearDown(() {
    cubit.close();
  });

  const tSession = AuthSessionEntity(
    userId: 'u1',
    email: 'guard@k.id',
    name: 'Budi',
    allowAdmin: false,
    allowPatrol: true,
    allowMonPatrol: false,
    groupUid: 'grp_1',
  );

  const tSessionNoGroup = AuthSessionEntity(
    userId: 'u1',
    email: 'guard@k.id',
    name: 'Budi',
    allowAdmin: false,
    allowPatrol: true,
    allowMonPatrol: false,
  );

  group('IncidentFormCubit Tests', () {
    test('initial state has general category and empty fields', () {
      expect(cubit.state.category, equals(IncidentCategory.general));
      expect(cubit.state.title, isEmpty);
      expect(cubit.state.photos, isEmpty);
    });

    test('validateTitle checks required and max length', () {
      expect(
        IncidentFormCubit.validateTitle(''),
        equals('Judul laporan wajib diisi'),
      );
      expect(
        IncidentFormCubit.validateTitle('   '),
        equals('Judul laporan wajib diisi'),
      );
      expect(
        IncidentFormCubit.validateTitle('a' * 129),
        equals('Judul laporan maksimal 128 karakter.'),
      );
      expect(IncidentFormCubit.validateTitle('Pagar Rusak'), isNull);
    });

    test('validateDescription checks max length', () {
      expect(
        IncidentFormCubit.validateDescription('a' * 1001),
        equals('Deskripsi kejadian maksimal 1000 karakter.'),
      );
      expect(IncidentFormCubit.validateDescription(''), isNull);
      expect(
        IncidentFormCubit.validateDescription('Deskripsi insiden'),
        isNull,
      );
    });

    test('updateTitle updates title, sets error, and clears errorMessage', () {
      cubit.updateTitle('Pagar Rusak');
      expect(cubit.state.title, equals('Pagar Rusak'));
      expect(cubit.state.titleError, isNull);

      cubit.updateTitle('');
      expect(cubit.state.titleError, equals('Judul laporan wajib diisi'));
    });

    test('updateDescription updates description and sets error', () {
      cubit.updateDescription('Kejadian di area timur');
      expect(cubit.state.description, equals('Kejadian di area timur'));
      expect(cubit.state.descriptionError, isNull);

      cubit.updateDescription('b' * 1005);
      expect(
        cubit.state.descriptionError,
        equals('Deskripsi kejadian maksimal 1000 karakter.'),
      );
    });

    test('addPhoto enforces maximum of 4 photos', () {
      for (var i = 0; i < 5; i++) {
        cubit.addPhoto(IncidentMediaItem(id: '$i', name: 'photo_$i.jpg'));
      }
      expect(cubit.state.photos.length, equals(4));
    });

    test('clearPhotos removes all photos from state', () {
      cubit.addPhoto(const IncidentMediaItem(id: '1', name: 'photo_1.jpg'));
      expect(cubit.state.photos.length, equals(1));
      cubit.clearPhotos();
      expect(cubit.state.photos, isEmpty);
    });

    test('reorderPhotos updates photos order correctly', () {
      cubit
        ..addPhotos(const [
          IncidentMediaItem(id: '1', name: 'p1.jpg'),
          IncidentMediaItem(id: '2', name: 'p2.jpg'),
          IncidentMediaItem(id: '3', name: 'p3.jpg'),
        ])
        ..reorderPhotos(2, 0);
      expect(cubit.state.photos.map((p) => p.id), equals(['3', '1', '2']));

      cubit.reorderPhotos(1, 2);
      expect(cubit.state.photos.map((p) => p.id), equals(['3', '2', '1']));
    });

    blocTest<IncidentFormCubit, IncidentFormState>(
      'submit rejects empty title with validation attempt and error',
      build: () => cubit,
      act: (c) => c.submit(session: tSession),
      expect: () => [
        predicate<IncidentFormState>(
          (s) =>
              s.titleError == 'Judul laporan wajib diisi' &&
              s.validationAttempt == 1 &&
              s.status == IncidentFormStatus.initial,
        ),
      ],
    );

    blocTest<IncidentFormCubit, IncidentFormState>(
      'submit rejects session without groupUid',
      build: () => cubit,
      seed: () => const IncidentFormState(title: 'Lampu Padam'),
      act: (c) => c.submit(session: tSessionNoGroup),
      expect: () => [
        predicate<IncidentFormState>(
          (s) =>
              s.errorMessage?.contains('Grup pengguna tidak ditemukan') ==
                  true &&
              s.validationAttempt == 1,
        ),
      ],
    );

    blocTest<IncidentFormCubit, IncidentFormState>(
      'submit silently ignores RequestCancelledFailure',
      build: () {
        when(
          () => mockCreateIncidentUseCase(any()),
        ).thenAnswer((_) async => const Left(RequestCancelledFailure()));
        return cubit;
      },
      seed: () => const IncidentFormState(title: 'Lampu Padam'),
      act: (c) => c.submit(session: tSession),
      expect: () => [
        predicate<IncidentFormState>(
          (s) => s.status == IncidentFormStatus.uploading,
        ),
        predicate<IncidentFormState>(
          (s) => s.status == IncidentFormStatus.submitting,
        ),
      ],
    );

    blocTest<IncidentFormCubit, IncidentFormState>(
      'submit emits failure on NoInternetFailure',
      build: () {
        when(
          () => mockCreateIncidentUseCase(any()),
        ).thenAnswer((_) async => const Left(NoInternetFailure()));
        return cubit;
      },
      seed: () => const IncidentFormState(title: 'Lampu Padam'),
      act: (c) => c.submit(session: tSession),
      expect: () => [
        predicate<IncidentFormState>(
          (s) => s.status == IncidentFormStatus.uploading,
        ),
        predicate<IncidentFormState>(
          (s) => s.status == IncidentFormStatus.submitting,
        ),
        predicate<IncidentFormState>(
          (s) =>
              s.status == IncidentFormStatus.failure &&
              s.errorMessage?.contains('Tidak ada koneksi internet') == true,
        ),
      ],
    );

    blocTest<IncidentFormCubit, IncidentFormState>(
      'submit successfully sends data and emits success with created incident',
      build: () {
        final tCreated = IncidentEntity(
          id: 'inc_new',
          groupId: 'grp_1',
          title: 'Pagar Rusak',
          status: IncidentStatus.open,
          createdBy: 'u1',
          createdAt: DateTime.now(),
        );

        when(
          () => mockCreateIncidentUseCase(any()),
        ).thenAnswer((_) async => Right(tCreated));
        return cubit;
      },
      seed: () => const IncidentFormState(title: 'Pagar Rusak'),
      act: (c) => c.submit(session: tSession),
      expect: () => [
        predicate<IncidentFormState>((s) => s.isUploading),
        predicate<IncidentFormState>((s) => s.isSubmitting),
        predicate<IncidentFormState>((s) {
          return s.status == IncidentFormStatus.success &&
              s.createdIncident?.id == 'inc_new';
        }),
      ],
    );
  });

  group('IncidentFormCubit photo upload', () {
    final tCreated = IncidentEntity(
      id: 'inc_new',
      groupId: 'grp_1',
      title: 'Pagar Rusak',
      status: IncidentStatus.open,
      createdBy: 'u1',
      createdAt: DateTime.now(),
    );

    IncidentMediaItem photo(int i) =>
        IncidentMediaItem(id: 'p$i', name: 'foto_$i.jpg', path: '/tmp/$i.jpg');

    Either<Failure, String> okUrl(AppMediaFile file) =>
        Right('https://cdn.kawalo.id/${file.name}.webp');

    void stubUpload(
      Future<Either<Failure, String>> Function(AppMediaFile file) answer,
    ) {
      when(
        () =>
            mockUpload.uploadImage(any(), onProgress: any(named: 'onProgress')),
      ).thenAnswer(
        (inv) => answer(inv.positionalArguments.first as AppMediaFile),
      );
    }

    void stubCreateOk() {
      when(
        () => mockCreateIncidentUseCase(any()),
      ).thenAnswer((_) async => Right(tCreated));
    }

    CreateIncidentParams capturedParams() =>
        verify(() => mockCreateIncidentUseCase(captureAny())).captured.single
            as CreateIncidentParams;

    test('uploads photos first and sends only the uploaded URLs', () async {
      stubUpload((f) async => okUrl(f));
      stubCreateOk();
      cubit
        ..updateTitle('Pagar Rusak')
        ..addPhotos([photo(1), photo(2)]);

      await cubit.submit(session: tSession);

      final params = capturedParams();
      expect(params.photos, [
        'https://cdn.kawalo.id/foto_1.jpg.webp',
        'https://cdn.kawalo.id/foto_2.jpg.webp',
      ]);
      expect(cubit.state.status, IncidentFormStatus.success);
      expect(cubit.state.photos.every((p) => p.isUploaded), isTrue);
    });

    test(
      'partial failure blocks the request and keeps per-photo status',
      () async {
        stubUpload(
          (f) async => f.name == 'foto_2.jpg'
              ? const Left(NetworkFailure('Koneksi terputus.'))
              : okUrl(f),
        );
        cubit
          ..updateTitle('Pagar Rusak')
          ..addPhotos([photo(1), photo(2)]);

        await cubit.submit(session: tSession);

        verifyNever(() => mockCreateIncidentUseCase(any()));
        expect(cubit.state.status, IncidentFormStatus.failure);
        expect(cubit.state.errorMessage, contains('1 foto gagal diunggah'));
        expect(cubit.state.photos[0].uploadStatus, IncidentUploadStatus.done);
        expect(cubit.state.photos[1].uploadStatus, IncidentUploadStatus.failed);
        expect(cubit.state.photos[1].uploadError, 'Koneksi terputus.');
        expect(cubit.state.canPressSubmit, isTrue);
      },
    );

    test('retryPhotoUpload re-sends only the failed photo', () async {
      var failSecond = true;
      stubUpload((f) async {
        if (f.name == 'foto_2.jpg' && failSecond) {
          return const Left(NetworkFailure('Koneksi terputus.'));
        }
        return okUrl(f);
      });
      stubCreateOk();
      cubit
        ..updateTitle('Pagar Rusak')
        ..addPhotos([photo(1), photo(2)]);
      await cubit.submit(session: tSession);

      failSecond = false;
      await cubit.retryPhotoUpload('p2');
      expect(cubit.state.photos[1].isUploaded, isTrue);

      await cubit.submit(session: tSession);

      // foto_1 once, foto_2 twice (failure + retry), nothing on resubmit.
      final uploaded = verify(
        () => mockUpload.uploadImage(
          captureAny(),
          onProgress: any(named: 'onProgress'),
        ),
      ).captured.cast<AppMediaFile>().map((f) => f.name).toList();
      expect(uploaded, ['foto_1.jpg', 'foto_2.jpg', 'foto_2.jpg']);
      expect(capturedParams().photos, hasLength(2));
      expect(cubit.state.status, IncidentFormStatus.success);
    });

    test('submit is blocked while uploading and reports progress', () async {
      final completer = Completer<Either<Failure, String>>();
      void Function(double)? report;
      when(
        () =>
            mockUpload.uploadImage(any(), onProgress: any(named: 'onProgress')),
      ).thenAnswer((inv) {
        report = inv.namedArguments[#onProgress] as void Function(double)?;
        return completer.future;
      });
      stubCreateOk();
      cubit
        ..updateTitle('Pagar Rusak')
        ..addPhoto(photo(1));

      final first = cubit.submit(session: tSession);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.isUploading, isTrue);
      expect(cubit.state.canPressSubmit, isFalse);

      report!(0.4);
      expect(cubit.state.photos.single.uploadProgress, 0.4);
      expect(cubit.state.photos.single.isUploading, isTrue);

      await cubit.submit(session: tSession); // ignored: already busy
      completer.complete(const Right('https://cdn.kawalo.id/a.webp'));
      await first;

      verify(
        () =>
            mockUpload.uploadImage(any(), onProgress: any(named: 'onProgress')),
      ).called(1);
      verify(() => mockCreateIncidentUseCase(any())).called(1);
    });

    test('uploads at most 3 photos in parallel', () async {
      var inFlight = 0;
      var peak = 0;
      stubUpload((f) async {
        inFlight++;
        peak = peak < inFlight ? inFlight : peak;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        inFlight--;
        return okUrl(f);
      });
      stubCreateOk();
      cubit
        ..updateTitle('Pagar Rusak')
        ..addPhotos([for (var i = 1; i <= 4; i++) photo(i)]);

      await cubit.submit(session: tSession);

      expect(peak, 3);
      expect(capturedParams().photos, hasLength(4));
    });
  });

  group('IncidentFormCubit location', () {
    final tCreated = IncidentEntity(
      id: 'inc_new',
      groupId: 'grp_1',
      title: 'Pagar Rusak',
      status: IncidentStatus.open,
      createdBy: 'u1',
      createdAt: DateTime.now(),
    );

    Position position(double lat, double lng) => Position(
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

    CreateIncidentParams capturedParams() =>
        verify(() => mockCreateIncidentUseCase(captureAny())).captured.single
            as CreateIncidentParams;

    test('resolveLocation stores the coordinates as a pair', () async {
      await cubit.resolveLocation(
        fetchPosition: () async =>
            LocationResult.success(position(-6.2, 106.8)),
      );

      expect(cubit.state.glat, -6.2);
      expect(cubit.state.glong, 106.8);
      expect(cubit.state.hasLocation, isTrue);
      expect(cubit.state.isResolvingLocation, isFalse);
      expect(cubit.state.locationError, isNull);
    });

    test(
      'permission denied leaves no location and an Indonesian message',
      () async {
        await cubit.resolveLocation(
          fetchPosition: () async => const LocationResult.permissionDenied(),
        );

        expect(cubit.state.hasLocation, isFalse);
        expect(cubit.state.glat, isNull);
        expect(cubit.state.glong, isNull);
        expect(cubit.state.locationError, 'Izin akses lokasi belum diberikan.');
      },
    );

    test('service disabled reports the reason', () async {
      await cubit.resolveLocation(
        fetchPosition: () async => const LocationResult.serviceDisabled(),
      );
      expect(
        cubit.state.locationError,
        'Layanan lokasi perangkat sedang nonaktif.',
      );
    });

    test(
      'report is still sent without location when permission is denied',
      () async {
        when(
          () => mockCreateIncidentUseCase(any()),
        ).thenAnswer((_) async => Right(tCreated));
        await cubit.resolveLocation(
          fetchPosition: () async => const LocationResult.permissionDenied(),
        );
        cubit.updateTitle('Pagar Rusak');

        await cubit.submit(session: tSession);

        final params = capturedParams();
        expect(params.glat, isNull);
        expect(params.glong, isNull);
        expect(cubit.state.status, IncidentFormStatus.success);
      },
    );

    test('submit sends glat and glong together', () async {
      when(
        () => mockCreateIncidentUseCase(any()),
      ).thenAnswer((_) async => Right(tCreated));
      await cubit.resolveLocation(
        fetchPosition: () async =>
            LocationResult.success(position(-6.2, 106.8)),
      );
      cubit.updateTitle('Pagar Rusak');

      await cubit.submit(session: tSession);

      final params = capturedParams();
      expect(params.glat, -6.2);
      expect(params.glong, 106.8);
    });

    test('updateLocation with half a pair clears the location', () {
      cubit.updateLocation(lat: -6.2, long: 106.8);
      expect(cubit.state.hasLocation, isTrue);

      cubit.updateLocation(lat: -6.2);
      expect(cubit.state.glat, isNull);
      expect(cubit.state.glong, isNull);
    });

    test(
      'clearLocation drops the location and ignores a late lookup',
      () async {
        final completer = Completer<LocationResult>();
        final pending = cubit.resolveLocation(
          fetchPosition: () => completer.future,
        );
        expect(cubit.state.isResolvingLocation, isTrue);

        cubit.clearLocation();
        completer.complete(LocationResult.success(position(1, 2)));
        await pending;

        expect(cubit.state.hasLocation, isFalse);
        expect(cubit.state.isResolvingLocation, isFalse);
      },
    );
  });
}
