import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
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

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCreateIncidentParams());
  });

  late MockCreateIncidentUseCase mockCreateIncidentUseCase;
  late IncidentFormCubit cubit;

  setUp(() {
    mockCreateIncidentUseCase = MockCreateIncidentUseCase();
    cubit = IncidentFormCubit(createIncidentUseCase: mockCreateIncidentUseCase);
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
        predicate<IncidentFormState>((s) => s.isSubmitting),
        predicate<IncidentFormState>((s) {
          return s.status == IncidentFormStatus.success &&
              s.createdIncident?.id == 'inc_new';
        }),
      ],
    );
  });
}
