import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/update_guest/update_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/update_guest/update_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/guest_identity_type.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/update_guest_data.dart';
import 'package:mocktail/mocktail.dart';

class MockGuestRepository extends Mock implements GuestRepository {}

class MockAppCancellationToken extends Mock implements AppCancellationToken {}

void main() {
  late UpdateGuestUseCase useCase;
  late MockGuestRepository mockRepository;

  const tSessionAdmin = AuthSessionEntity(
    userId: '1',
    email: 'admin@kawalo.id',
    name: 'Admin User',
    role: 'ADMIN',
    allowAdmin: true,
    allowPatrol: false,
    allowMonPatrol: false,
  );

  const tSessionGuardCreator = AuthSessionEntity(
    userId: '2',
    email: 'creator@kawalo.id',
    name: 'Guard Creator',
    role: 'GUARD',
    allowAdmin: false,
    allowPatrol: true,
    allowMonPatrol: false,
  );

  const tSessionGuardOther = AuthSessionEntity(
    userId: '3',
    email: 'other@kawalo.id',
    name: 'Guard Other',
    role: 'GUARD',
    allowAdmin: false,
    allowPatrol: true,
    allowMonPatrol: false,
  );

  const tSessionCitizen = AuthSessionEntity(
    userId: '4',
    email: 'citizen@kawalo.id',
    name: 'Citizen User',
    role: 'CITIZEN',
    allowAdmin: false,
    allowPatrol: false,
    allowMonPatrol: false,
  );

  const tItem = GuestItemEntity(
    id: '101',
    guestName: 'Budi Santoso',
    guestDestination: 'Blok A No. 1',
    guestType: 'TAMU',
    guestCreatorEmail: 'creator@kawalo.id',
  );

  setUpAll(() {
    registerFallbackValue(
      const UpdateGuestData(id: 'fallback_id', guestName: 'Fallback'),
    );
    registerFallbackValue(
      const UpdateGuestParams(id: 'fallback_id', guestName: 'Fallback'),
    );
  });

  setUp(() {
    mockRepository = MockGuestRepository();
    useCase = UpdateGuestUseCase(mockRepository);
  });

  const tParams = UpdateGuestParams(
    id: '101',
    guestName: 'Budi Santoso Revisi',
    guestDestination: 'Blok B No. 2',
    guestType: 'TAMU',
    guestPurpose: 'Kunjungan keluarga',
    guestNumber: 'B 9999 XX',
    guestIdentity: '3171012345678',
    guestIdentityType: 'KTP',
    guestAddress: 'Jakarta Barat',
    guestToUserEmail: 'warga@kawalo.id',
    guestPhoto: 'https://example.com/photo.jpg',
    session: tSessionAdmin,
    item: tItem,
  );

  const tResultEntity = GuestItemEntity(
    id: '101',
    guestName: 'Budi Santoso Revisi',
    guestDestination: 'Blok B No. 2',
    guestType: 'TAMU',
    guestPurpose: 'Kunjungan keluarga',
    guestNumber: 'B 9999 XX',
    guestIdentity: '3171012345678',
    guestIdentityType: 'KTP',
    guestAddress: 'Jakarta Barat',
    guestToUserEmail: 'warga@kawalo.id',
    guestPhoto: 'https://example.com/photo.jpg',
  );

  group('UpdateGuestParams Tests', () {
    test('isValidId returns true for valid numeric id', () {
      expect(tParams.isValidId, isTrue);
    });

    test('isValidId returns false for non-numeric or empty id', () {
      const emptyIdParams = UpdateGuestParams(
        id: '',
        session: tSessionAdmin,
        item: tItem,
      );
      expect(emptyIdParams.isValidId, isFalse);

      const alphaIdParams = UpdateGuestParams(
        id: 'abc-123',
        session: tSessionAdmin,
        item: tItem,
      );
      expect(alphaIdParams.isValidId, isFalse);
    });

    test('isAuthorized delegates to item.canBeUpdatedBySession', () {
      const adminParams = UpdateGuestParams(
        id: '101',
        session: tSessionAdmin,
        item: tItem,
      );
      expect(adminParams.isAuthorized, isTrue);

      const creatorParams = UpdateGuestParams(
        id: '101',
        session: tSessionGuardCreator,
        item: tItem,
      );
      expect(creatorParams.isAuthorized, isTrue);

      const otherGuardParams = UpdateGuestParams(
        id: '101',
        session: tSessionGuardOther,
        item: tItem,
      );
      expect(otherGuardParams.isAuthorized, isFalse);

      const citizenParams = UpdateGuestParams(
        id: '101',
        session: tSessionCitizen,
        item: tItem,
      );
      expect(citizenParams.isAuthorized, isFalse);

      const nullItemParams = UpdateGuestParams(
        id: '101',
        session: tSessionAdmin,
      );
      expect(nullItemParams.isAuthorized, isFalse);

      const mismatchedItemParams = UpdateGuestParams(
        id: '101',
        session: tSessionAdmin,
        item: GuestItemEntity(id: '999'),
      );
      expect(mismatchedItemParams.isAuthorized, isFalse);
    });

    test('toRepositoryData creates UpdateGuestData accurately', () {
      final repoData = tParams.toRepositoryData();

      expect(repoData.id, tParams.id);
      expect(repoData.guestName, tParams.guestName);
      expect(repoData.guestDestination, tParams.guestDestination);
      expect(repoData.guestType, tParams.guestType);
      expect(repoData.guestPurpose, tParams.guestPurpose);
      expect(repoData.guestNumber, tParams.guestNumber);
      expect(repoData.guestIdentity, tParams.guestIdentity);
      expect(repoData.guestIdentityType, tParams.guestIdentityType);
      expect(repoData.guestAddress, tParams.guestAddress);
      expect(repoData.guestToUserEmail, tParams.guestToUserEmail);
      expect(repoData.guestPhoto, tParams.guestPhoto);
      expect(repoData.cancelToken, tParams.cancelToken);
    });

    test('allowedIdentityTypes matches GuestIdentityType.allowedCodes', () {
      expect(
        UpdateGuestParams.allowedIdentityTypes,
        GuestIdentityType.allowedCodes,
      );
      expect(
        UpdateGuestData.allowedIdentityTypes,
        GuestIdentityType.allowedCodes,
      );
    });

    test('props equality works correctly', () {
      const otherParams = UpdateGuestParams(
        id: '101',
        guestName: 'Budi Santoso Revisi',
        guestDestination: 'Blok B No. 2',
        guestType: 'TAMU',
        guestPurpose: 'Kunjungan keluarga',
        guestNumber: 'B 9999 XX',
        guestIdentity: '3171012345678',
        guestIdentityType: 'KTP',
        guestAddress: 'Jakarta Barat',
        guestToUserEmail: 'warga@kawalo.id',
        guestPhoto: 'https://example.com/photo.jpg',
        session: tSessionAdmin,
        item: tItem,
      );
      expect(tParams, equals(otherParams));
    });
  });

  group('UpdateGuestUseCase Execution Tests', () {
    test('returns ValidationFailure when isValidId is false', () async {
      const invalidParams = UpdateGuestParams(
        id: 'invalid-id',
        session: tSessionAdmin,
        item: tItem,
      );

      final result = await useCase(invalidParams);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(
            failure.message,
            'ID tamu wajib diisi dan harus berupa angka valid.',
          );
        },
        (_) => fail('Should not be Right'),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns ForbiddenFailure when isAuthorized is false', () async {
      const forbiddenParams = UpdateGuestParams(
        id: '101',
        session: tSessionCitizen,
        item: tItem,
      );

      final result = await useCase(forbiddenParams);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ForbiddenFailure>());
          expect(
            failure.message,
            'Anda tidak memiliki izin untuk mengubah data tamu ini.',
          );
        },
        (_) => fail('Should not be Right'),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('delegates to repository on success for authorized caller', () async {
      when(() => mockRepository.updateGuest(any()))
          .thenAnswer((_) async => const Right(tResultEntity));

      final result = await useCase(tParams);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should be Right'),
        (entity) => expect(entity, equals(tResultEntity)),
      );

      verify(() => mockRepository.updateGuest(tParams.toRepositoryData()))
          .called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('forwards cancelToken via toRepositoryData to repository', () async {
      final token = MockAppCancellationToken();
      final paramsWithToken = UpdateGuestParams(
        id: '101',
        guestName: 'Budi Revisi',
        session: tSessionAdmin,
        item: tItem,
        cancelToken: token,
      );
      when(() => mockRepository.updateGuest(any()))
          .thenAnswer((_) async => const Right(tResultEntity));

      final result = await useCase(paramsWithToken);

      expect(result.isRight(), isTrue);
      verify(
        () => mockRepository.updateGuest(paramsWithToken.toRepositoryData()),
      ).called(1);
    });

    test('returns failure when repository fails', () async {
      const tFailure = ServerFailure('Gagal memperbarui data tamu');
      when(() => mockRepository.updateGuest(any()))
          .thenAnswer((_) async => const Left(tFailure));

      final result = await useCase(tParams);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, equals(tFailure)),
        (_) => fail('Should be Left'),
      );
      verify(() => mockRepository.updateGuest(tParams.toRepositoryData()))
          .called(1);
    });
  });
}
