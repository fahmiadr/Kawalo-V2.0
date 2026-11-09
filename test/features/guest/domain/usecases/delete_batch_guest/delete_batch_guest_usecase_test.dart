import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_batch_guest/delete_batch_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_batch_guest/delete_batch_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/delete_batch_result.dart';
import 'package:mocktail/mocktail.dart';

class MockGuestRepository extends Mock implements GuestRepository {}

class MockAppCancellationToken extends Mock implements AppCancellationToken {}

void main() {
  late DeleteBatchGuestUseCase deleteBatchUseCase;
  late MockGuestRepository mockRepository;

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

  const tItem1 = GuestItemEntity(
    id: '1',
    guestName: 'Guest 1',
    guestCreatorEmail: 'creator@example.com',
  );

  const tItem2 = GuestItemEntity(
    id: '2',
    guestName: 'Guest 2',
    guestCreatorEmail: 'creator@example.com',
  );

  const tItemOther = GuestItemEntity(
    id: '3',
    guestName: 'Guest 3',
    guestCreatorEmail: 'other@example.com',
  );

  setUp(() {
    mockRepository = MockGuestRepository();
    deleteBatchUseCase = DeleteBatchGuestUseCase(mockRepository);
  });

  group('DeleteBatchGuestParams Tests', () {
    test('isValid returns true when all ids are numeric strings', () {
      const params = DeleteBatchGuestParams(
        ids: ['1', '2', '345'],
        session: tSessionAdmin,
        items: [tItem1, tItem2],
      );
      expect(params.isValid, isTrue);
    });

    test('isValid returns false when ids is empty', () {
      const params = DeleteBatchGuestParams(
        ids: [],
        session: tSessionAdmin,
        items: [],
      );
      expect(params.isValid, isFalse);
    });

    test('isValid returns false when any id contains non-numeric chars', () {
      expect(
        const DeleteBatchGuestParams(
          ids: ['1', 'abc'],
          session: tSessionAdmin,
          items: [],
        ).isValid,
        isFalse,
      );
      expect(
        const DeleteBatchGuestParams(
          ids: ['1', '  '],
          session: tSessionAdmin,
          items: [],
        ).isValid,
        isFalse,
      );
      expect(
        const DeleteBatchGuestParams(
          ids: ['1', '12a3'],
          session: tSessionAdmin,
          items: [],
        ).isValid,
        isFalse,
      );
      expect(
        const DeleteBatchGuestParams(
          ids: ['-1', '2'],
          session: tSessionAdmin,
          items: [],
        ).isValid,
        isFalse,
      );
    });

    test(
      'isAuthorized returns true for ADMIN even if items created by others',
      () {
        const params = DeleteBatchGuestParams(
          ids: ['1', '3'],
          session: tSessionAdmin,
          items: [tItem1, tItemOther],
        );
        expect(params.isAuthorized, isTrue);
      },
    );

    test('isAuthorized returns true for GUARD when all items are owned', () {
      const params = DeleteBatchGuestParams(
        ids: ['1', '2'],
        session: tSessionGuardCreator,
        items: [tItem1, tItem2],
      );
      expect(params.isAuthorized, isTrue);
    });

    test('isAuthorized returns false for GUARD when at least one item is not '
        'owned', () {
      const params = DeleteBatchGuestParams(
        ids: ['1', '3'],
        session: tSessionGuardCreator,
        items: [tItem1, tItemOther],
      );
      expect(params.isAuthorized, isFalse);
    });

    test('isAuthorized returns false if any id is missing from items list '
        '(fail-closed)', () {
      const params = DeleteBatchGuestParams(
        ids: ['1', '99'],
        session: tSessionAdmin,
        items: [tItem1],
      );
      expect(params.isAuthorized, isFalse);
    });

    test('isAuthorized returns false when session is null', () {
      const params = DeleteBatchGuestParams(
        ids: ['1'],
        session: null,
        items: [tItem1],
      );
      expect(params.isAuthorized, isFalse);
    });

    test('props contains ids, session, items, cancelToken', () {
      final token = MockAppCancellationToken();
      final params1 = DeleteBatchGuestParams(
        ids: const ['1', '2'],
        session: tSessionAdmin,
        items: const [tItem1, tItem2],
        cancelToken: token,
      );
      final params2 = DeleteBatchGuestParams(
        ids: const ['1', '2'],
        session: tSessionAdmin,
        items: const [tItem1, tItem2],
        cancelToken: token,
      );
      expect(params1, equals(params2));
    });
  });

  group('DeleteBatchGuestUseCase Tests', () {
    const tResult = DeleteBatchResult(deletedCount: 2);
    const tValidIds = ['1', '2'];

    test('returns ValidationFailure without calling repository when ids '
        'are invalid', () async {
      final result = await deleteBatchUseCase(
        const DeleteBatchGuestParams(
          ids: ['abc'],
          session: tSessionAdmin,
          items: [],
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(
          (failure as ValidationFailure).message,
          contains('Daftar ID tamu tidak boleh kosong'),
        );
      }, (_) => fail('Should not succeed'));
      verifyZeroInteractions(mockRepository);
    });

    test('returns ForbiddenFailure without calling repository when user is not '
        'authorized', () async {
      final result = await deleteBatchUseCase(
        const DeleteBatchGuestParams(
          ids: ['1', '3'],
          session: tSessionGuardOther,
          items: [tItem1, tItemOther],
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ForbiddenFailure>());
        expect(
          failure.message,
          'Anda tidak memiliki izin untuk menghapus salah satu data tamu '
          'yang dipilih.',
        );
      }, (_) => fail('Should not succeed'));
      verifyZeroInteractions(mockRepository);
    });

    test('delegates to repository when ids are valid and authorized', () async {
      when(
        () => mockRepository.deleteBatchGuests(
          ids: any(named: 'ids'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => const Right(tResult));

      final result = await deleteBatchUseCase(
        const DeleteBatchGuestParams(
          ids: tValidIds,
          session: tSessionAdmin,
          items: [tItem1, tItem2],
        ),
      );

      expect(result, const Right<Failure, DeleteBatchResult>(tResult));
      verify(() => mockRepository.deleteBatchGuests(ids: tValidIds)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('returns Failure when repository returns Left', () async {
      const failure = ServerFailure('Kesalahan internal server.', 500);
      when(
        () => mockRepository.deleteBatchGuests(
          ids: any(named: 'ids'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      final result = await deleteBatchUseCase(
        const DeleteBatchGuestParams(
          ids: tValidIds,
          session: tSessionAdmin,
          items: [tItem1, tItem2],
        ),
      );

      expect(result, const Left<Failure, DeleteBatchResult>(failure));
      verify(() => mockRepository.deleteBatchGuests(ids: tValidIds)).called(1);
    });
  });
}
