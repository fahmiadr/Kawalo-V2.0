import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/repositories/information_repository.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/delete_batch_information/delete_batch_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/delete_batch_information/delete_batch_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/delete_batch_result.dart';
import 'package:mocktail/mocktail.dart';

class MockInformationRepository extends Mock implements InformationRepository {}

class MockAppCancellationToken extends Mock implements AppCancellationToken {}

void main() {
  late DeleteBatchInformationUseCase deleteBatchUseCase;
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

  const tItem1 = InformationItemEntity(
    id: '1',
    photos: [],
    title: 'Item 1',
    userEmail: 'creator@example.com',
  );

  const tItem2 = InformationItemEntity(
    id: '2',
    photos: [],
    title: 'Item 2',
    userEmail: 'creator@example.com',
  );

  const tItemOther = InformationItemEntity(
    id: '3',
    photos: [],
    title: 'Item 3',
    userEmail: 'someoneelse@example.com',
  );

  setUp(() {
    mockRepository = MockInformationRepository();
    deleteBatchUseCase = DeleteBatchInformationUseCase(mockRepository);
  });

  group('DeleteBatchInformationParams Tests', () {
    test('preserves ids passed on construction', () {
      const params = DeleteBatchInformationParams(
        ids: ['1', '2', '3'],
        session: tSessionAdmin,
        items: [tItem1, tItem2, tItemOther],
      );
      expect(params.ids, ['1', '2', '3']);
      expect(params.isValid, isTrue);
    });

    test('isValid returns true for valid non-empty numeric ids', () {
      const params = DeleteBatchInformationParams(
        ids: ['10', '20', '30'],
        session: tSessionAdmin,
        items: [],
      );
      expect(params.isValid, isTrue);
    });

    test('isValid returns false for empty list or blank items', () {
      expect(
        const DeleteBatchInformationParams(
          ids: [],
          session: tSessionAdmin,
          items: [],
        ).isValid,
        isFalse,
      );
      expect(
        const DeleteBatchInformationParams(
          ids: ['   ', ''],
          session: tSessionAdmin,
          items: [],
        ).isValid,
        isFalse,
      );
    });

    test('isValid returns false if any id is non-numeric', () {
      expect(
        const DeleteBatchInformationParams(
          ids: ['1', 'abc', '3'],
          session: tSessionAdmin,
          items: [],
        ).isValid,
        isFalse,
      );
      expect(
        const DeleteBatchInformationParams(
          ids: ['12a'],
          session: tSessionAdmin,
          items: [],
        ).isValid,
        isFalse,
      );
      expect(
        const DeleteBatchInformationParams(
          ids: ['-1'],
          session: tSessionAdmin,
          items: [],
        ).isValid,
        isFalse,
      );
    });

    test('isAuthorized evaluates all items properly', () {
      expect(
        const DeleteBatchInformationParams(
          ids: ['1', '2'],
          session: tSessionAdmin,
          items: [tItem1, tItem2],
        ).isAuthorized,
        isTrue,
      );
      expect(
        const DeleteBatchInformationParams(
          ids: ['1', '2'],
          session: tSessionGuardCreator,
          items: [tItem1, tItem2],
        ).isAuthorized,
        isTrue,
      );
      expect(
        const DeleteBatchInformationParams(
          ids: ['1', '3'],
          session: tSessionGuardCreator,
          items: [tItem1, tItemOther],
        ).isAuthorized,
        isFalse,
      );
      expect(
        const DeleteBatchInformationParams(
          ids: ['1', '2'],
          session: tSessionGuardOther,
          items: [tItem1, tItem2],
        ).isAuthorized,
        isFalse,
      );
    });

    test('props contains ids, session, items, and cancelToken', () {
      final token = MockAppCancellationToken();
      final params1 = DeleteBatchInformationParams(
        ids: const ['1', '2'],
        session: tSessionAdmin,
        items: const [tItem1, tItem2],
        cancelToken: token,
      );
      final params2 = DeleteBatchInformationParams(
        ids: const ['1', '2'],
        session: tSessionAdmin,
        items: const [tItem1, tItem2],
        cancelToken: token,
      );
      expect(params1, equals(params2));
    });
  });

  group('DeleteBatchInformationUseCase Tests', () {
    const tResult = DeleteBatchResult(deletedCount: 2);
    const tValidIds = ['1', '2'];

    test(
      'returns ValidationFailure without calling repository when ids '
      'are invalid',
      () async {
        final result = await deleteBatchUseCase(
          const DeleteBatchInformationParams(
            ids: ['abc'],
            session: tSessionAdmin,
            items: [],
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(
              (failure as ValidationFailure).message,
              contains('Daftar ID informasi tidak boleh kosong'),
            );
          },
          (_) => fail('Should not succeed'),
        );
        verifyZeroInteractions(mockRepository);
      },
    );

    test(
      'returns ForbiddenFailure when unauthorized',
      () async {
        final result = await deleteBatchUseCase(
          const DeleteBatchInformationParams(
            ids: tValidIds,
            session: tSessionGuardOther,
            items: [tItem1, tItem2],
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ForbiddenFailure>());
            expect(
              (failure as ForbiddenFailure).message,
              contains('Anda tidak memiliki izin untuk menghapus salah satu'),
            );
          },
          (_) => fail('Should not succeed'),
        );
        verifyZeroInteractions(mockRepository);
      },
    );

    test(
      'delegates to repository when ids are valid and authorized',
      () async {
        when(
          () => mockRepository.deleteBatchInformation(
            ids: any(named: 'ids'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => const Right(tResult));

        final result = await deleteBatchUseCase(
          const DeleteBatchInformationParams(
            ids: tValidIds,
            session: tSessionAdmin,
            items: [tItem1, tItem2],
          ),
        );

        expect(result, const Right<Failure, DeleteBatchResult>(tResult));
        verify(
          () => mockRepository.deleteBatchInformation(
            ids: tValidIds,
          ),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      },
    );

    test(
      'returns Failure when repository returns Left',
      () async {
        const failure = ServerFailure('Kesalahan internal server.', 500);
        when(
          () => mockRepository.deleteBatchInformation(
            ids: any(named: 'ids'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => const Left(failure));

        final result = await deleteBatchUseCase(
          const DeleteBatchInformationParams(
            ids: tValidIds,
            session: tSessionAdmin,
            items: [tItem1, tItem2],
          ),
        );

        expect(result, const Left<Failure, DeleteBatchResult>(failure));
        verify(
          () => mockRepository.deleteBatchInformation(
            ids: tValidIds,
          ),
        ).called(1);
      },
    );
  });
}
