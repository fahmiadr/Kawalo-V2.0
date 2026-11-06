import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/create_guest/create_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/create_guest/create_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/create_guest_data.dart';
import 'package:mocktail/mocktail.dart';

class MockGuestRepository extends Mock implements GuestRepository {}

class MockAppCancellationToken extends Mock implements AppCancellationToken {}

void main() {
  late CreateGuestUseCase useCase;
  late MockGuestRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(
      const CreateGuestData(
        guestName: 'Fallback',
        guestDestination: 'Fallback',
        guestType: 'TAMU',
      ),
    );
  });

  setUp(() {
    mockRepository = MockGuestRepository();
    useCase = CreateGuestUseCase(mockRepository);
  });

  const tParams = CreateGuestParams(
    guestName: 'Budi Santoso',
    guestDestination: 'Blok A No. 1',
    guestType: 'TAMU',
    guestPurpose: 'Kunjungan kerja',
    guestNumber: 'B 1234 CD',
    guestIdentity: '3171012345678',
    guestIdentityType: 'KTP',
    guestAddress: 'Jakarta',
    guestToUserEmail: 'user@example.com',
  );

  const tCreatedGuest = GuestItemEntity(
    id: 'guest_101',
    guestName: 'Budi Santoso',
    guestCategory: 'Tamu',
    guestDestination: 'Blok A No. 1',
    guestPurpose: 'Kunjungan kerja',
    guestDt: '2026-09-21T10:00:00.000Z',
  );

  group('CreateGuestUseCase Execution Tests', () {
    test('delegates to repository and returns entity on success', () async {
      when(() => mockRepository.createGuest(any()))
          .thenAnswer((_) async => const Right(tCreatedGuest));

      final result = await useCase(tParams);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should be Right'),
        (entity) => expect(entity, equals(tCreatedGuest)),
      );

      verify(() => mockRepository.createGuest(tParams.toRepositoryData()))
          .called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('forwards cancelToken to repository', () async {
      final token = MockAppCancellationToken();
      final tParamsWithToken = const CreateGuestParams(
        guestName: 'Budi Santoso',
        guestDestination: 'Blok A No. 1',
        guestType: 'TAMU',
      ).copyWithCancelToken(token);
      when(() => mockRepository.createGuest(any()))
          .thenAnswer((_) async => const Right(tCreatedGuest));

      final result = await useCase(tParamsWithToken);

      expect(result.isRight(), isTrue);
      verify(
        () => mockRepository.createGuest(tParamsWithToken.toRepositoryData()),
      ).called(1);
    });

    test('returns failure when repository fails', () async {
      const tFailure = ServerFailure('Gagal menyimpan data tamu');
      when(() => mockRepository.createGuest(any()))
          .thenAnswer((_) async => const Left(tFailure));

      final result = await useCase(tParams);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, equals(tFailure)),
        (_) => fail('Should be Left'),
      );
      verify(() => mockRepository.createGuest(tParams.toRepositoryData()))
          .called(1);
    });
  });
}

extension on CreateGuestParams {
  CreateGuestParams copyWithCancelToken(AppCancellationToken token) {
    return CreateGuestParams(
      guestName: guestName,
      guestDestination: guestDestination,
      guestType: guestType,
      guestPurpose: guestPurpose,
      guestNumber: guestNumber,
      guestIdentity: guestIdentity,
      guestIdentityType: guestIdentityType,
      guestAddress: guestAddress,
      guestToUserEmail: guestToUserEmail,
      guestPhoto: guestPhoto,
      guestDt: guestDt,
      cancelToken: token,
    );
  }
}
