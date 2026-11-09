import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_validators.dart';

void main() {
  group('GuestFormValidators', () {
    test('validateName requires a non-blank value up to 128 chars', () {
      expect(GuestFormValidators.validateName(''), 'Nama tamu wajib diisi');
      expect(GuestFormValidators.validateName('   '), 'Nama tamu wajib diisi');
      expect(
        GuestFormValidators.validateName('a' * 129),
        'Nama tamu maksimal 128 karakter.',
      );
      expect(GuestFormValidators.validateName('a' * 128), isNull);
    });

    test('validateDestination requires a non-blank value up to 128 chars', () {
      expect(
        GuestFormValidators.validateDestination(' '),
        'Destinasi kunjungan wajib diisi',
      );
      expect(
        GuestFormValidators.validateDestination('a' * 129),
        'Destinasi kunjungan maksimal 128 karakter.',
      );
      expect(GuestFormValidators.validateDestination('Blok A1'), isNull);
    });

    test('validateGuestType requires a non-blank value up to 64 chars', () {
      expect(
        GuestFormValidators.validateGuestType(''),
        'Tipe tamu wajib dipilih.',
      );
      expect(
        GuestFormValidators.validateGuestType('a' * 65),
        'Tipe tamu maksimal 64 karakter.',
      );
      expect(GuestFormValidators.validateGuestType('TAMU'), isNull);
    });

    test('validateIdentityNumber is only enforced when required', () {
      expect(
        GuestFormValidators.validateIdentityNumber(
          '',
          isIdentityRequired: false,
        ),
        isNull,
      );
      expect(
        GuestFormValidators.validateIdentityNumber(
          'a' * 100,
          isIdentityRequired: false,
        ),
        isNull,
      );
      expect(
        GuestFormValidators.validateIdentityNumber(
          '  ',
          isIdentityRequired: true,
        ),
        'Nomor identitas wajib diisi jika jenis identitas dipilih.',
      );
      expect(
        GuestFormValidators.validateIdentityNumber(
          'a' * 65,
          isIdentityRequired: true,
        ),
        'Nomor identitas maksimal 64 karakter.',
      );
      expect(
        GuestFormValidators.validateIdentityNumber(
          '3201234567890001',
          isIdentityRequired: true,
        ),
        isNull,
      );
    });

    test('optional fields only enforce their max length', () {
      expect(GuestFormValidators.validateGuestNumber(''), isNull);
      expect(GuestFormValidators.validateGuestNumber('a' * 32), isNull);
      expect(
        GuestFormValidators.validateGuestNumber('a' * 33),
        'Nomor tamu maksimal 32 karakter.',
      );

      expect(GuestFormValidators.validatePurpose('a' * 128), isNull);
      expect(
        GuestFormValidators.validatePurpose('a' * 129),
        'Keperluan kunjungan maksimal 128 karakter.',
      );

      expect(GuestFormValidators.validateAddress('a' * 512), isNull);
      expect(
        GuestFormValidators.validateAddress('a' * 513),
        'Alamat asal maksimal 512 karakter.',
      );
    });
  });
}
