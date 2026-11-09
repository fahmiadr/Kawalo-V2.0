import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_guest/delete_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_guest/delete_guest_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockGuestRepository extends Mock implements GuestRepository {}

class MockAppCancellationToken extends Mock implements AppCancellationToken {}

void main() {
  late DeleteGuestUseCase deleteGuestUseCase;
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

  const tItem = GuestItemEntity(
    id: '42',
    guestName: 'John Doe',
    guestCreatorEmail: 'creator@example.com',
  );

  setUp(() {
    mockRepository = MockGuestRepository();
    deleteGuestUseCase = DeleteGuestUseCase(mockRepository);
  });

  group('DeleteGuestParams Tests', () {
    test('preserves id and returns false for id with whitespace', () {
      const params = DeleteGuestParams(
        id: '  42  ',
        session: tSessionAdmin,
        item: tItem,
      );
      expect(params.id, '  42  ');
      expect(params.isValidId, isFalse);
    });

    test('isValidId returns true for valid numeric id', () {
      const params = DeleteGuestParams(
        id: '12345',
        session: tSessionAdmin,
        item: tItem,
      );
      expect(params.isValidId, isTrue);
    });

    test('isValidId returns false for empty or non-numeric id', () {
      expect(
        const DeleteGuestParams(
          id: '',
          session: tSessionAdmin,
          item: tItem,
        ).isValidId,
        isFalse,
      );
      expect(
        const DeleteGuestParams(
          id: '   ',
          session: tSessionAdmin,
          item: tItem,
        ).isValidId,
        isFalse,
      );
      expect(
        const DeleteGuestParams(
          id: 'abc',
          session: tSessionAdmin,
          item: tItem,
        ).isValidId,
        isFalse,
      );
      expect(
        const DeleteGuestParams(
          id: '12a3',
          session: tSessionAdmin,
          item: tItem,
        ).isValidId,
        isFalse,
      );
      expect(
        const DeleteGuestParams(
          id: '-5',
          session: tSessionAdmin,
          item: tItem,
        ).isValidId,
        isFalse,
      );
    });

    test('isAuthorized evaluates permission correctly', () {
      expect(
        const DeleteGuestParams(
          id: '42',
          session: tSessionAdmin,
          item: tItem,
        ).isAuthorized,
        isTrue,
      );
      expect(
        const DeleteGuestParams(
          id: '42',
          session: tSessionGuardCreator,
          item: tItem,
        ).isAuthorized,
        isTrue,
      );
      expect(
        const DeleteGuestParams(
          id: '42',
          session: tSessionGuardOther,
          item: tItem,
        ).isAuthorized,
        isFalse,
      );
      expect(
        const DeleteGuestParams(
          id: '42',
          session: null,
          item: tItem,
        ).isAuthorized,
        isFalse,
      );
      expect(
        const DeleteGuestParams(
          id: '42',
          session: tSessionAdmin,
          item: null,
        ).isAuthorized,
        isFalse,
      );
    });

    test('props contains id, session, item, cancelToken', () {
      final token = MockAppCancellationToken();
      final params1 = DeleteGuestParams(
        id: '10',
        session: tSessionAdmin,
        item: tItem,
        cancelToken: token,
      );
      final params2 = DeleteGuestParams(
        id: '10',
        session: tSessionAdmin,
        item: tItem,
        cancelToken: token,
      );
      expect(params1, equals(params2));
    });
  });

  group('DeleteGuestUseCase Tests', () {
    const tValidId = '42';

    test(
      'returns ValidationFailure without calling repository when id is invalid',
      () async {
        final result = await deleteGuestUseCase(
          const DeleteGuestParams(
            id: 'invalid-id',
            session: tSessionAdmin,
            item: tItem,
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          expect(
            failure.message,
            'ID tamu wajib diisi dan harus berupa angka valid.',
          );
        }, (_) => fail('Should be Left'));
        verifyZeroInteractions(mockRepository);
      },
    );

    test('returns ForbiddenFailure when user is not authorized', () async {
      final result = await deleteGuestUseCase(
        const DeleteGuestParams(
          id: tValidId,
          session: tSessionGuardOther,
          item: tItem,
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ForbiddenFailure>());
        expect(
          failure.message,
          'Anda tidak memiliki izin untuk menghapus data tamu ini.',
        );
      }, (_) => fail('Should be Left'));
      verifyZeroInteractions(mockRepository);
    });

    test(
      'delegates to repository and returns Right(null) on success',
      () async {
        when(
          () => mockRepository.deleteGuest(
            id: any(named: 'id'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => const Right(null));

        final result = await deleteGuestUseCase(
          const DeleteGuestParams(
            id: tValidId,
            session: tSessionAdmin,
            item: tItem,
          ),
        );

        expect(result.isRight(), isTrue);
        verify(() => mockRepository.deleteGuest(id: tValidId)).called(1);
        verifyNoMoreInteractions(mockRepository);
      },
    );

    test('forwards cancelToken to repository', () async {
      final token = MockAppCancellationToken();
      when(
        () => mockRepository.deleteGuest(
          id: any(named: 'id'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => const Right(null));

      final result = await deleteGuestUseCase(
        DeleteGuestParams(
          id: tValidId,
          session: tSessionGuardCreator,
          item: tItem,
          cancelToken: token,
        ),
      );

      expect(result.isRight(), isTrue);
      verify(
        () => mockRepository.deleteGuest(id: tValidId, cancelToken: token),
      ).called(1);
    });

    test('returns Failure when repository returns failure', () async {
      const tFailure = ServerFailure(
        'Hanya Admin atau Petugas yang dapat menghapus.',
      );
      when(
        () => mockRepository.deleteGuest(
          id: any(named: 'id'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      final result = await deleteGuestUseCase(
        const DeleteGuestParams(
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
