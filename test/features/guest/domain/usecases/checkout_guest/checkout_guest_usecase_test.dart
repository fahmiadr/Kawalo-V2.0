import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/checkout_guest/checkout_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/checkout_guest/checkout_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/checkout_guest_data.dart';
import 'package:mocktail/mocktail.dart';

class MockGuestRepository extends Mock implements GuestRepository {}

class MockAppCancellationToken extends Mock implements AppCancellationToken {}

void main() {
  late CheckoutGuestUseCase checkoutGuestUseCase;
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

  const tSessionGuard = AuthSessionEntity(
    userId: '2',
    email: 'guard@example.com',
    name: 'Guard Duty',
    role: 'GUARD',
    allowAdmin: false,
    allowPatrol: true,
    allowMonPatrol: true,
  );

  const tSessionResident = AuthSessionEntity(
    userId: '3',
    email: 'resident@example.com',
    name: 'Resident User',
    role: 'RESIDENT',
    allowAdmin: false,
    allowPatrol: false,
    allowMonPatrol: false,
  );

  const tActiveGuest = GuestItemEntity(
    id: '42',
    guestName: 'John Doe',
    guestCreatorEmail: 'creator@example.com',
  );

  const tUpdatedGuest = GuestItemEntity(
    id: '42',
    guestName: 'John Doe',
    guestCreatorEmail: 'creator@example.com',
    guestOutDt: '2026-11-02T12:00:00.000Z',
    guestCheckoutByEmail: 'guard@example.com',
  );

  setUpAll(() {
    registerFallbackValue(const CheckoutGuestData(id: 'fallback'));
  });

  setUp(() {
    mockRepository = MockGuestRepository();
    checkoutGuestUseCase = CheckoutGuestUseCase(mockRepository);
  });

  group('CheckoutGuestParams Tests', () {
    test('isValidId returns true for valid id', () {
      const params = CheckoutGuestParams(
        id: '42',
        session: tSessionGuard,
        item: tActiveGuest,
      );
      expect(params.isValidId, isTrue);
    });

    test('isValidId returns false for empty id', () {
      const params = CheckoutGuestParams(
        id: '',
        session: tSessionGuard,
        item: tActiveGuest,
      );
      expect(params.isValidId, isFalse);
    });

    test('isAuthorized delegates to item.canBeCheckedOutBySession', () {
      const authorizedParams = CheckoutGuestParams(
        id: '42',
        session: tSessionGuard,
        item: tActiveGuest,
      );
      expect(authorizedParams.isAuthorized, isTrue);

      const unauthorizedParams = CheckoutGuestParams(
        id: '42',
        session: tSessionResident,
        item: tActiveGuest,
      );
      expect(unauthorizedParams.isAuthorized, isFalse);

      const mismatchedIdParams = CheckoutGuestParams(
        id: '99',
        session: tSessionGuard,
        item: tActiveGuest,
      );
      expect(mismatchedIdParams.isAuthorized, isFalse);
    });
  });

  group('CheckoutGuestUseCase Execution Tests', () {
    test('returns ValidationFailure when ID is empty', () async {
      const params = CheckoutGuestParams(
        id: '',
        session: tSessionAdmin,
        item: tActiveGuest,
      );

      final result = await checkoutGuestUseCase(params);

      expect(
        result,
        const Left<Failure, GuestItemEntity>(
          ValidationFailure(
            'ID tamu wajib diisi dan memiliki format yang valid.',
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns ForbiddenFailure when not authorized', () async {
      const params = CheckoutGuestParams(
        id: '42',
        session: tSessionResident,
        item: tActiveGuest,
      );

      final result = await checkoutGuestUseCase(params);

      expect(
        result,
        const Left<Failure, GuestItemEntity>(
          ForbiddenFailure(
            'Anda tidak memiliki izin untuk melakukan check-out tamu ini.',
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test(
      'delegates to repository and returns updated guest on success',
      () async {
        when(() => mockRepository.checkoutGuest(any())).thenAnswer(
          (_) async => const Right<Failure, GuestItemEntity>(tUpdatedGuest),
        );

        const params = CheckoutGuestParams(
          id: '42',
          session: tSessionGuard,
          item: tActiveGuest,
          qrUid: 'QR-42',
        );

        final result = await checkoutGuestUseCase(params);

        expect(result, const Right<Failure, GuestItemEntity>(tUpdatedGuest));
        verify(
          () => mockRepository.checkoutGuest(
            const CheckoutGuestData(id: '42', qrUid: 'QR-42'),
          ),
        ).called(1);
      },
    );
  });
}
