import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/repositories/information_repository.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/update_information/update_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/update_information/update_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/update_information_data.dart';
import 'package:mocktail/mocktail.dart';

class MockInformationRepository extends Mock implements InformationRepository {}

class MockAppCancellationToken extends Mock implements AppCancellationToken {}

void main() {
  late UpdateInformationUseCase useCase;
  late MockInformationRepository mockRepository;

  const tSessionAdmin = AuthSessionEntity(
    userId: '1',
    email: 'admin@example.com',
    name: 'Admin User',
    role: 'ADMIN',
    allowAdmin: true,
    allowPatrol: false,
    allowMonPatrol: false,
  );

  const tSessionGuardCreator = AuthSessionEntity(
    userId: '2',
    email: 'creator@example.com',
    name: 'Guard Creator',
    role: 'GUARD',
    allowAdmin: false,
    allowPatrol: true,
    allowMonPatrol: false,
  );

  const tSessionGuardOther = AuthSessionEntity(
    userId: '3',
    email: 'other@example.com',
    name: 'Guard Other',
    role: 'GUARD',
    allowAdmin: false,
    allowPatrol: true,
    allowMonPatrol: false,
  );

  const tSessionCitizen = AuthSessionEntity(
    userId: '4',
    email: 'citizen@example.com',
    name: 'Citizen User',
    role: 'CITIZEN',
    allowAdmin: false,
    allowPatrol: false,
    allowMonPatrol: false,
  );

  const tItem = InformationItemEntity(
    id: '123',
    photos: [],
    title: 'Pengumuman Penting',
    userEmail: 'creator@example.com',
  );

  setUpAll(() {
    registerFallbackValue(
      const UpdateInformationData(id: 'fallback_id', title: 'Fallback'),
    );
    registerFallbackValue(
      const UpdateInformationParams(id: 'fallback_id', title: 'Fallback'),
    );
  });

  setUp(() {
    mockRepository = MockInformationRepository();
    useCase = UpdateInformationUseCase(mockRepository);
  });

  const tParams = UpdateInformationParams(
    id: '123',
    title: 'Pengumuman Penting Revisi',
    text: 'Akan diadakan pemadaman listrik berkala hari Minggu.',
    feedType: 'GENERAL',
    session: tSessionAdmin,
    item: tItem,
  );

  const tResultEntity = InformationItemEntity(
    id: '123',
    photos: [],
    title: 'Pengumuman Penting Revisi',
    text: 'Akan diadakan pemadaman listrik berkala hari Minggu.',
    feedType: 'GENERAL',
  );

  group('UpdateInformationParams Tests', () {
    test('isValidId returns true for valid numeric id', () {
      const params = UpdateInformationParams(
        id: '123',
        session: tSessionAdmin,
        item: tItem,
      );
      expect(params.isValidId, isTrue);
    });

    test(
      'isValidId returns false for empty, whitespace, or non-numeric id',
      () {
      expect(
        const UpdateInformationParams(
          id: '',
          session: tSessionAdmin,
          item: tItem,
        ).isValidId,
        isFalse,
      );
      expect(
        const UpdateInformationParams(
          id: '   ',
          session: tSessionAdmin,
          item: tItem,
        ).isValidId,
        isFalse,
      );
      expect(
        const UpdateInformationParams(
          id: 'abc',
          session: tSessionAdmin,
          item: tItem,
        ).isValidId,
        isFalse,
      );
    });

    test('isAuthorized returns true for ADMIN', () {
      const params = UpdateInformationParams(
        id: '123',
        session: tSessionAdmin,
        item: tItem,
      );
      expect(params.isAuthorized, isTrue);
    });

    test('isAuthorized returns true for GUARD if author email matches', () {
      const params = UpdateInformationParams(
        id: '123',
        session: tSessionGuardCreator,
        item: tItem,
      );
      expect(params.isAuthorized, isTrue);
    });

    test('isAuthorized returns false for GUARD if not author', () {
      const params = UpdateInformationParams(
        id: '123',
        session: tSessionGuardOther,
        item: tItem,
      );
      expect(params.isAuthorized, isFalse);
    });

    test('isAuthorized returns false for CITIZEN or null session or null item',
        () {
      expect(
        const UpdateInformationParams(
          id: '123',
          session: tSessionCitizen,
          item: tItem,
        ).isAuthorized,
        isFalse,
      );

      expect(
        const UpdateInformationParams(
          id: '123',
          session: tSessionAdmin,
        ).isAuthorized,
        isFalse,
      );
    });
  });

  group('UpdateInformationUseCase Execution Tests', () {
    test('returns ValidationFailure when isValidId is false', () async {
      const invalidIdParams = UpdateInformationParams(
        id: 'abc',
        session: tSessionAdmin,
        item: tItem,
      );

      final result = await useCase(invalidIdParams);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(
            failure.message,
            'ID informasi wajib diisi dan harus berupa angka valid.',
          );
        },
        (_) => fail('Should be Left'),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns ForbiddenFailure when isAuthorized is false', () async {
      const unauthorizedParams = UpdateInformationParams(
        id: '123',
        session: tSessionGuardOther,
        item: tItem,
      );

      final result = await useCase(unauthorizedParams);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ForbiddenFailure>());
          expect(
            failure.message,
            'Anda tidak memiliki izin untuk mengubah informasi ini.',
          );
        },
        (_) => fail('Should be Left'),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('delegates to repository and returns entity on success', () async {
      when(() => mockRepository.updateInformation(any()))
          .thenAnswer((_) async => const Right(tResultEntity));

      final result = await useCase(tParams);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should be Right'),
        (entity) => expect(entity, equals(tResultEntity)),
      );

      verify(
        () => mockRepository.updateInformation(tParams.toRepositoryData()),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('forwards cancelToken to repository', () async {
      final token = MockAppCancellationToken();
      final tParamsWithToken = UpdateInformationParams(
        id: '123',
        title: 'Pengumuman Penting Revisi',
        session: tSessionAdmin,
        item: tItem,
        cancelToken: token,
      );
      when(() => mockRepository.updateInformation(any()))
          .thenAnswer((_) async => const Right(tResultEntity));

      final result = await useCase(tParamsWithToken);

      expect(result.isRight(), isTrue);
      verify(
        () => mockRepository
            .updateInformation(tParamsWithToken.toRepositoryData()),
      ).called(1);
    });

    test('returns failure when repository fails', () async {
      const tFailure = ServerFailure('Koneksi database bermasalah.');
      when(() => mockRepository.updateInformation(any()))
          .thenAnswer((_) async => const Left(tFailure));

      final result = await useCase(tParams);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, equals(tFailure)),
        (_) => fail('Should be Left'),
      );
    });
  });
}
