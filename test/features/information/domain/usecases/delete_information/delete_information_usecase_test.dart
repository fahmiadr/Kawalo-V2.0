import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/repositories/information_repository.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/delete_information/delete_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/delete_information/delete_information_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockInformationRepository extends Mock implements InformationRepository {}

class MockAppCancellationToken extends Mock implements AppCancellationToken {}

void main() {
  late DeleteInformationUseCase deleteInformationUseCase;
  late MockInformationRepository mockRepository;

  const tSessionAdmin = AuthSessionEntity(
    userId: '1',
    email: 'admin@example.com',
    name: 'Admin User',
    role: 'ADMIN',
    allowAdmin: true,
    allowPatrol: true,
    allowMonPatrol: true,
  );

  const tSessionGuardCreator = AuthSessionEntity(
    userId: '2',
    email: 'creator@example.com',
    name: 'Guard Creator',
    role: 'GUARD',
    allowAdmin: false,
    allowPatrol: true,
    allowMonPatrol: true,
  );

  const tSessionGuardOther = AuthSessionEntity(
    userId: '3',
    email: 'other@example.com',
    name: 'Guard Other',
    role: 'GUARD',
    allowAdmin: false,
    allowPatrol: true,
    allowMonPatrol: true,
  );

  const tItem = InformationItemEntity(
    id: '42',
    photos: [],
    title: 'Pengumuman Penting',
    userEmail: 'creator@example.com',
  );

  setUp(() {
    mockRepository = MockInformationRepository();
    deleteInformationUseCase = DeleteInformationUseCase(mockRepository);
  });

  group('DeleteInformationParams Tests', () {
    test('preserves id and returns false for id with whitespace', () {
      const params = DeleteInformationParams(
        id: '  42  ',
        session: tSessionAdmin,
        item: tItem,
      );
      expect(params.id, '  42  ');
      expect(params.isValidId, isFalse);
    });

    test('isValidId returns true for valid numeric id', () {
      const params = DeleteInformationParams(
        id: '12345',
        session: tSessionAdmin,
        item: tItem,
      );
      expect(params.isValidId, isTrue);
    });

    test('isValidId returns false for empty or non-numeric id', () {
      expect(
        const DeleteInformationParams(
          id: '',
          session: tSessionAdmin,
          item: tItem,
        ).isValidId,
        isFalse,
      );
      expect(
        const DeleteInformationParams(
          id: '   ',
          session: tSessionAdmin,
          item: tItem,
        ).isValidId,
        isFalse,
      );
      expect(
        const DeleteInformationParams(
          id: 'abc',
          session: tSessionAdmin,
          item: tItem,
        ).isValidId,
        isFalse,
      );
      expect(
        const DeleteInformationParams(
          id: '12a3',
          session: tSessionAdmin,
          item: tItem,
        ).isValidId,
        isFalse,
      );
      expect(
        const DeleteInformationParams(
          id: '-5',
          session: tSessionAdmin,
          item: tItem,
        ).isValidId,
        isFalse,
      );
    });

    test('isAuthorized evaluates permission correctly', () {
      expect(
        const DeleteInformationParams(
          id: '42',
          session: tSessionAdmin,
          item: tItem,
        ).isAuthorized,
        isTrue,
      );
      expect(
        const DeleteInformationParams(
          id: '42',
          session: tSessionGuardCreator,
          item: tItem,
        ).isAuthorized,
        isTrue,
      );
      expect(
        const DeleteInformationParams(
          id: '42',
          session: tSessionGuardOther,
          item: tItem,
        ).isAuthorized,
        isFalse,
      );
      expect(
        const DeleteInformationParams(
          id: '42',
          session: null,
          item: tItem,
        ).isAuthorized,
        isFalse,
      );
      expect(
        const DeleteInformationParams(
          id: '42',
          session: tSessionAdmin,
          item: null,
        ).isAuthorized,
        isFalse,
      );
    });

    test('props contains id, session, item, cancelToken', () {
      final token = MockAppCancellationToken();
      final params1 = DeleteInformationParams(
        id: '10',
        session: tSessionAdmin,
        item: tItem,
        cancelToken: token,
      );
      final params2 = DeleteInformationParams(
        id: '10',
        session: tSessionAdmin,
        item: tItem,
        cancelToken: token,
      );
      expect(params1, equals(params2));
    });
  });

  group('DeleteInformationUseCase Tests', () {
    const tValidId = '42';

    test(
      'returns ValidationFailure without calling repository when id is invalid',
      () async {
        final result = await deleteInformationUseCase(
          const DeleteInformationParams(
            id: 'invalid-id',
            session: tSessionAdmin,
            item: tItem,
          ),
        );

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
      },
    );

    test(
      'returns ForbiddenFailure when user is not authorized',
      () async {
        final result = await deleteInformationUseCase(
          const DeleteInformationParams(
            id: tValidId,
            session: tSessionGuardOther,
            item: tItem,
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ForbiddenFailure>());
            expect(
              failure.message,
              'Anda tidak memiliki izin untuk menghapus informasi ini.',
            );
          },
          (_) => fail('Should be Left'),
        );
        verifyZeroInteractions(mockRepository);
      },
    );

    test(
      'delegates to repository and returns Right(null) on success',
      () async {
        when(
          () => mockRepository.deleteInformation(
            id: any(named: 'id'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => const Right(null));

        final result = await deleteInformationUseCase(
          const DeleteInformationParams(
            id: tValidId,
            session: tSessionAdmin,
            item: tItem,
          ),
        );

        expect(result.isRight(), isTrue);
        verify(
          () => mockRepository.deleteInformation(
            id: tValidId,
          ),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      },
    );

    test('forwards cancelToken to repository', () async {
      final token = MockAppCancellationToken();
      when(
        () => mockRepository.deleteInformation(
          id: any(named: 'id'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => const Right(null));

      final result = await deleteInformationUseCase(
        DeleteInformationParams(
          id: tValidId,
          session: tSessionGuardCreator,
          item: tItem,
          cancelToken: token,
        ),
      );

      expect(result.isRight(), isTrue);
      verify(
        () => mockRepository.deleteInformation(
          id: tValidId,
          cancelToken: token,
        ),
      ).called(1);
    });

    test('returns Failure when repository returns failure', () async {
      const tFailure =
          ServerFailure('Hanya Admin atau Petugas yang dapat menghapus.');
      when(
        () => mockRepository.deleteInformation(
          id: any(named: 'id'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      final result = await deleteInformationUseCase(
        const DeleteInformationParams(
          id: tValidId,
          session: tSessionAdmin,
          item: tItem,
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(
          failure.message,
          'Hanya Admin atau Petugas yang dapat menghapus.',
        ),
        (_) => fail('Should be Left'),
      );
    });
  });
}
