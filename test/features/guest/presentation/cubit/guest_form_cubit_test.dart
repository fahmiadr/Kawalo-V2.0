import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/master_guest_type_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/create_guest/create_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/create_guest/create_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/update_guest/update_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/update_guest/update_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_state.dart';
import 'package:mocktail/mocktail.dart';
import '../../../information/upload_test_helpers.dart';

class MockCreateGuestUseCase extends Mock implements CreateGuestUseCase {}

class MockUpdateGuestUseCase extends Mock implements UpdateGuestUseCase {}

class MockGuestRepository extends Mock implements GuestRepository {}

void main() {
  late MockCreateGuestUseCase mockCreateGuestUseCase;
  late MockUpdateGuestUseCase mockUpdateGuestUseCase;
  late MockGuestRepository mockGuestRepository;

  const dummySession = AuthSessionEntity(
    userId: '1',
    email: 'admin@kawalo.id',
    name: 'Admin',
    role: 'ADMIN',
    allowAdmin: true,
    allowPatrol: true,
    allowMonPatrol: true,
  );

  const sampleMasterTypes = [
    MasterGuestTypeEntity(id: '1', uid: 'uid-1', name: 'TAMU'),
    MasterGuestTypeEntity(id: '2', uid: 'uid-2', name: 'KURIR'),
  ];

  const sampleGuest = GuestItemEntity(
    id: '123',
    guestName: 'Budi Santoso',
    guestDestination: 'Blok A1 No. 5',
    guestType: 'TAMU',
    guestIdentity: '3201234567890001',
    guestIdentityType: 'KTP',
    guestNumber: 'B 1234 CD',
    guestPurpose: 'Kunjungan keluarga',
    guestAddress: 'Jl. Mawar No. 10',
    guestToUserEmail: 'wisnu@kawalo.id',
    guestToUserName: 'Wisnu Wijayadi',
    guestPhoto: 'https://cdn.kawalo.internal/guests/photos/budi.jpg',
  );

  setUpAll(() {
    registerFallbackValue(
      const CreateGuestParams(
        guestName: 'Dummy',
        guestDestination: 'Dummy Dest',
        guestType: 'TAMU',
      ),
    );
    registerFallbackValue(const UpdateGuestParams(id: '123'));
  });

  setUp(() {
    mockCreateGuestUseCase = MockCreateGuestUseCase();
    mockUpdateGuestUseCase = MockUpdateGuestUseCase();
    mockGuestRepository = MockGuestRepository();

    when(
      () => mockGuestRepository.getMasterGuestTypes(
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) async => const Right(sampleMasterTypes));
  });

  GuestFormCubit createCubit({GuestItemEntity? initialItem}) {
    return GuestFormCubit(
      uploadRepository: FakeUploadRepository(),
      createGuestUseCase: mockCreateGuestUseCase,
      updateGuestUseCase: mockUpdateGuestUseCase,
      guestRepository: mockGuestRepository,
      initialItem: initialItem,
    );
  }

  group('GuestFormCubit - Initialization', () {
    test(
      'initializes in create mode with empty fields and loads master data',
      () async {
        final cubit = createCubit();

        expect(cubit.state.isCreateMode, isTrue);
        expect(cubit.state.name, isEmpty);
        expect(cubit.state.destination, isEmpty);
        expect(cubit.state.guestType, isEmpty);
        expect(cubit.state.identityType, isNull);
        expect(cubit.state.identityNumber, isEmpty);
        expect(cubit.state.isDirty, isFalse);

        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.masterTypes, sampleMasterTypes);

        await cubit.close();
      },
    );

    test('initializes in update mode with initial item populated', () async {
      final cubit = createCubit(initialItem: sampleGuest);

      expect(cubit.state.isUpdateMode, isTrue);
      expect(cubit.state.name, 'Budi Santoso');
      expect(cubit.state.destination, 'Blok A1 No. 5');
      expect(cubit.state.guestType, 'TAMU');
      expect(cubit.state.identityType, 'KTP');
      expect(cubit.state.identityNumber, '3201234567890001');
      expect(cubit.state.guestNumber, 'B 1234 CD');
      expect(cubit.state.purpose, 'Kunjungan keluarga');
      expect(cubit.state.address, 'Jl. Mawar No. 10');
      expect(cubit.state.hostName, 'Wisnu Wijayadi');
      expect(cubit.state.isDirty, isFalse);

      await cubit.close();
    });
  });

  group('GuestFormCubit - Input Handlers & Validation', () {
    test('onNameChanged validates and updates state', () async {
      final cubit = createCubit()..onNameChanged('');
      expect(cubit.state.nameError, isNotNull);

      cubit.onNameChanged('Ahmad Dahlan');
      expect(cubit.state.name, 'Ahmad Dahlan');
      expect(cubit.state.nameError, isNull);

      await cubit.close();
    });

    test('onDestinationChanged validates required', () async {
      final cubit = createCubit()..onDestinationChanged('');
      expect(cubit.state.destinationError, isNotNull);

      cubit.onDestinationChanged('Pos 1');
      expect(cubit.state.destination, 'Pos 1');
      expect(cubit.state.destinationError, isNull);

      await cubit.close();
    });

    test('onGuestTypeChanged validates selection', () async {
      final cubit = createCubit()..onGuestTypeChanged('');
      expect(cubit.state.typeError, isNotNull);

      cubit.onGuestTypeChanged('TAMU');
      expect(cubit.state.guestType, 'TAMU');
      expect(cubit.state.typeError, isNull);

      await cubit.close();
    });

    test('onIdentityTypeChanged clears identityNumber when null', () async {
      final cubit = createCubit()..onIdentityTypeChanged('KTP');
      expect(cubit.state.identityType, 'KTP');
      expect(cubit.state.hasIdentityType, isTrue);

      cubit.onIdentityNumberChanged('12345');
      expect(cubit.state.identityNumber, '12345');

      cubit.onIdentityTypeChanged(null);
      expect(cubit.state.identityType, isNull);
      expect(cubit.state.identityNumber, isEmpty);
      expect(cubit.state.hasIdentityType, isFalse);

      await cubit.close();
    });

    test('isDirty detects modifications accurately in update mode', () async {
      final cubit = createCubit(initialItem: sampleGuest);
      expect(cubit.state.isDirty, isFalse);

      cubit.onNameChanged('Budi Santoso Updated');
      expect(cubit.state.isDirty, isTrue);

      cubit.onNameChanged('Budi Santoso');
      expect(cubit.state.isDirty, isFalse);

      await cubit.close();
    });
  });

  group('GuestFormCubit - Submission', () {
    test(
      'submit rejects when required fields are empty and sets errors',
      () async {
        final cubit = createCubit();

        await cubit.submit(session: dummySession);

        expect(cubit.state.validationAttempt, 1);
        expect(cubit.state.nameError, isNotNull);
        expect(cubit.state.destinationError, isNotNull);
        expect(cubit.state.typeError, isNotNull);
        expect(cubit.state.isSubmitting, isFalse);

        verifyNever(() => mockCreateGuestUseCase(any()));
        await cubit.close();
      },
    );

    test(
      'submit in create mode calls CreateGuestUseCase and succeeds',
      () async {
        when(
          () => mockCreateGuestUseCase(any()),
        ).thenAnswer((_) async => const Right(sampleGuest));

        final cubit = createCubit()
          ..onNameChanged('Budi Santoso')
          ..onDestinationChanged('Blok A1 No. 5')
          ..onGuestTypeChanged('TAMU')
          ..onIdentityTypeChanged('KTP')
          ..onIdentityNumberChanged('3201234567890001');

        await cubit.submit(session: dummySession);

        expect(cubit.state.status, GuestFormStatus.success);
        expect(cubit.state.createdOrUpdatedItem, sampleGuest);
        verify(() => mockCreateGuestUseCase(any())).called(1);

        await cubit.close();
      },
    );

    test(
      'submit in update mode calls UpdateGuestUseCase and succeeds',
      () async {
        const updatedGuest = GuestItemEntity(
          id: '123',
          guestName: 'Budi Santoso Refactored',
          guestDestination: 'Blok B2 No. 10',
          guestType: 'TAMU',
        );

        when(
          () => mockUpdateGuestUseCase(any()),
        ).thenAnswer((_) async => const Right(updatedGuest));

        final cubit = createCubit(initialItem: sampleGuest)
          ..onNameChanged('Budi Santoso Refactored')
          ..onDestinationChanged('Blok B2 No. 10');

        await cubit.submit(session: dummySession);

        expect(cubit.state.status, GuestFormStatus.success);
        expect(cubit.state.createdOrUpdatedItem, updatedGuest);
        verify(() => mockUpdateGuestUseCase(any())).called(1);

        await cubit.close();
      },
    );

    test('create sends the typed host name and no host email', () async {
      when(
        () => mockCreateGuestUseCase(any()),
      ).thenAnswer((_) async => const Right(sampleGuest));

      final cubit = createCubit()
        ..onNameChanged('Budi')
        ..onDestinationChanged('Blok A')
        ..onGuestTypeChanged('TAMU')
        ..onHostNameChanged('  Pak Slamet ');
      expect(cubit.state.isDirty, isTrue);

      await cubit.submit(session: dummySession);

      final params =
          verify(() => mockCreateGuestUseCase(captureAny())).captured.single
              as CreateGuestParams;
      expect(params.guestToName, 'Pak Slamet');
      expect(params.guestToUserEmail, isNull);

      await cubit.close();
    });

    test('create leaves the host name null when blank', () async {
      when(
        () => mockCreateGuestUseCase(any()),
      ).thenAnswer((_) async => const Right(sampleGuest));

      final cubit = createCubit()
        ..onNameChanged('Budi')
        ..onDestinationChanged('Blok A')
        ..onGuestTypeChanged('TAMU')
        ..onHostNameChanged('   ');

      await cubit.submit(session: dummySession);

      final params =
          verify(() => mockCreateGuestUseCase(captureAny())).captured.single
              as CreateGuestParams;
      expect(params.guestToName, isNull);

      await cubit.close();
    });

    test('onHostNameChanged rejects names over 128 characters', () async {
      final cubit = createCubit()
        ..onNameChanged('Budi')
        ..onDestinationChanged('Blok A')
        ..onGuestTypeChanged('TAMU')
        ..onHostNameChanged('x' * 129);
      expect(cubit.state.hostNameError, isNotNull);
      expect(cubit.state.isValid, isFalse);
      expect(cubit.state.firstInvalidField, 'hostName');

      cubit.onHostNameChanged('x' * 128);
      expect(cubit.state.hostNameError, isNull);
      expect(cubit.state.isValid, isTrue);

      await cubit.close();
    });

    test(
      'update keeps the linked host email when the host is untouched',
      () async {
        when(
          () => mockUpdateGuestUseCase(any()),
        ).thenAnswer((_) async => const Right(sampleGuest));

        final cubit = createCubit(initialItem: sampleGuest)
          ..onNameChanged('Budi Revisi');
        await cubit.submit(session: dummySession);

        final params =
            verify(() => mockUpdateGuestUseCase(captureAny())).captured.single
                as UpdateGuestParams;
        expect(params.guestToUserEmail, 'wisnu@kawalo.id');
        expect(params.guestToName, isNull);

        await cubit.close();
      },
    );

    test(
      'update with a retyped host sets the name and clears the email',
      () async {
        when(
          () => mockUpdateGuestUseCase(any()),
        ).thenAnswer((_) async => const Right(sampleGuest));

        final cubit = createCubit(initialItem: sampleGuest)
          ..onHostNameChanged('Pak Slamet');
        expect(cubit.state.isDirty, isTrue);
        await cubit.submit(session: dummySession);

        final params =
            verify(() => mockUpdateGuestUseCase(captureAny())).captured.single
                as UpdateGuestParams;
        expect(params.guestToName, 'Pak Slamet');
        expect(params.guestToUserEmail, isNull);
        expect(params.includeNulls, isTrue);

        await cubit.close();
      },
    );

    test(
      'update prefers the stored typed name over the account name',
      () async {
        const typed = GuestItemEntity(
          id: '9',
          guestName: 'Ani',
          guestDestination: 'A',
          guestType: 'TAMU',
          guestToName: 'Pak Slamet',
        );
        final cubit = createCubit(initialItem: typed);
        expect(cubit.state.hostName, 'Pak Slamet');
        expect(cubit.state.isDirty, isFalse);

        cubit.onHostNameChanged('');
        expect(cubit.state.isDirty, isTrue);

        await cubit.close();
      },
    );

    test('submit emits failure when use case returns Failure', () async {
      when(() => mockCreateGuestUseCase(any())).thenAnswer(
        (_) async => const Left(ServerFailure('Gagal menyimpan tamu')),
      );

      final cubit = createCubit()
        ..onNameChanged('Budi Santoso')
        ..onDestinationChanged('Blok A1 No. 5')
        ..onGuestTypeChanged('TAMU');

      await cubit.submit(session: dummySession);

      expect(cubit.state.status, GuestFormStatus.failure);
      expect(cubit.state.errorMessage, 'Gagal menyimpan tamu');

      await cubit.close();
    });
  });
}
