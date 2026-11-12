import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawalo_mobile/features/auth/presentation/cubit/change_password_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('ChangePasswordRules', () {
    test('new password: 8..64 characters after trim', () {
      expect(ChangePasswordRules.newPassword('', 'x'), isNull);
      expect(ChangePasswordRules.newPassword('short', 'x'), isNotNull);
      expect(ChangePasswordRules.newPassword('  short  ', 'x'), isNotNull);
      expect(ChangePasswordRules.newPassword('12345678', 'x'), isNull);
      expect(ChangePasswordRules.newPassword('a' * 64, 'x'), isNull);
      expect(ChangePasswordRules.newPassword('a' * 65, 'x'), isNotNull);
    });

    test('new password must differ from the current one', () {
      expect(
        ChangePasswordRules.newPassword('sama-sama-1', ' sama-sama-1 '),
        'Password baru harus berbeda dari password saat ini.',
      );
    });

    test('repeat must match', () {
      expect(ChangePasswordRules.repeat('', 'abc'), isNull);
      expect(ChangePasswordRules.repeat('abc', 'abc'), isNull);
      expect(ChangePasswordRules.repeat('abd', 'abc'), isNotNull);
    });

    test('isValid needs all three fields', () {
      bool valid(String c, String n, String r) =>
          ChangePasswordRules.isValid(current: c, newValue: n, repeatValue: r);
      expect(valid('lama', 'baru-1234', 'baru-1234'), isTrue);
      expect(valid('', 'baru-1234', 'baru-1234'), isFalse);
      expect(valid('lama', 'baru-1234', ''), isFalse);
      expect(valid('lama', 'baru-1234', 'baru-12345'), isFalse);
      expect(valid('lama', 'pendek', 'pendek'), isFalse);
      expect(valid('baru-1234', 'baru-1234', 'baru-1234'), isFalse);
    });
  });

  group('ChangePasswordCubit', () {
    late _MockAuthRepository repository;

    setUp(() => repository = _MockAuthRepository());

    blocTest<ChangePasswordCubit, ChangePasswordState>(
      'sends the trimmed passwords and ends in success',
      build: () => ChangePasswordCubit(repository),
      setUp: () => when(
        () => repository.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenAnswer((_) async => const Right(null)),
      act: (cubit) =>
          cubit.submit(currentPassword: ' lama ', newPassword: ' baru-1234 '),
      expect: () => const [
        ChangePasswordState(status: ChangePasswordStatus.saving),
        ChangePasswordState(status: ChangePasswordStatus.success),
      ],
      verify: (_) => verify(
        () => repository.changePassword(
          currentPassword: 'lama',
          newPassword: 'baru-1234',
        ),
      ).called(1),
    );

    blocTest<ChangePasswordCubit, ChangePasswordState>(
      '403 AUTH_INVALID_CREDENTIALS becomes wrongCurrent, not a generic error',
      build: () => ChangePasswordCubit(repository),
      setUp: () =>
          when(
            () => repository.changePassword(
              currentPassword: any(named: 'currentPassword'),
              newPassword: any(named: 'newPassword'),
            ),
          ).thenAnswer(
            (_) async => const Left(
              ServerFailure(
                'Password saat ini salah.',
                403,
                'AUTH_INVALID_CREDENTIALS',
              ),
            ),
          ),
      act: (cubit) =>
          cubit.submit(currentPassword: 'salah', newPassword: 'baru-1234'),
      expect: () => const [
        ChangePasswordState(status: ChangePasswordStatus.saving),
        ChangePasswordState(
          status: ChangePasswordStatus.wrongCurrent,
          message: 'Password saat ini salah.',
        ),
      ],
    );

    blocTest<ChangePasswordCubit, ChangePasswordState>(
      'other errors keep the server message',
      build: () => ChangePasswordCubit(repository),
      setUp: () =>
          when(
            () => repository.changePassword(
              currentPassword: any(named: 'currentPassword'),
              newPassword: any(named: 'newPassword'),
            ),
          ).thenAnswer(
            (_) async => const Left(
              ServerFailure('Password baru terlalu lemah.', 422, 'VALIDATION'),
            ),
          ),
      act: (cubit) =>
          cubit.submit(currentPassword: 'lama', newPassword: 'baru-1234'),
      expect: () => const [
        ChangePasswordState(status: ChangePasswordStatus.saving),
        ChangePasswordState(
          status: ChangePasswordStatus.failed,
          message: 'Password baru terlalu lemah.',
        ),
      ],
    );
  });
}
