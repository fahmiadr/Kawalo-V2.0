import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/utils/app_validator.dart';

void main() {
  group('AppValidator.validateRequired', () {
    test('returns null when value is non-empty', () {
      expect(AppValidator.validateRequired('John Doe'), isNull);
      expect(
        AppValidator.validateRequired('Budi', fieldName: 'Nama tamu'),
        isNull,
      );
    });

    test(
      'returns formatted error using fieldName when value is null or empty',
      () {
      expect(
        AppValidator.validateRequired(null, fieldName: 'Nama tamu'),
        equals('Nama tamu wajib diisi'),
      );
      expect(
        AppValidator.validateRequired('', fieldName: 'Nama tamu'),
        equals('Nama tamu wajib diisi'),
      );
      expect(
        AppValidator.validateRequired('   ', fieldName: 'Destinasi tujuan'),
        equals('Destinasi tujuan wajib diisi'),
      );
    });

    test('returns customMessage when provided on empty value', () {
      expect(
        AppValidator.validateRequired(
          null,
          customMessage: 'Harap isi email terlebih dahulu.',
        ),
        equals('Harap isi email terlebih dahulu.'),
      );
      expect(
        AppValidator.validateRequired(
          '   ',
          fieldName: 'Email',
          customMessage: 'Harap isi email terlebih dahulu.',
        ),
        equals('Harap isi email terlebih dahulu.'),
      );
    });

    test(
      'returns default message when neither fieldName nor customMessage '
      'is given',
      () {
      expect(
        AppValidator.validateRequired(null),
        equals('Field ini wajib diisi'),
      );
      expect(
        AppValidator.validateRequired(''),
        equals('Field ini wajib diisi'),
      );
    });
  });

  group('AppValidator.validateEmail', () {
    test('returns error when value is null or empty', () {
      expect(
        AppValidator.validateEmail(null),
        equals('Harap isi email terlebih dahulu.'),
      );
      expect(
        AppValidator.validateEmail(''),
        equals('Harap isi email terlebih dahulu.'),
      );
      expect(
        AppValidator.validateEmail('   '),
        equals('Harap isi email terlebih dahulu.'),
      );
    });

    test('returns error when email exceeds maximum length (254 chars)', () {
      final longLocal = 'a' * 60;
      final longDomain =
          '${'b' * 60}.${'c' * 60}.${'d' * 60}.${'e' * 60}.com';
      final longEmail = '$longLocal@$longDomain';

      expect(longEmail.length, greaterThan(254));
      expect(
        AppValidator.validateEmail(longEmail),
        contains('Email melebihi batas panjang maksimum'),
      );
    });

    test('returns error when local-part exceeds 64 chars', () {
      final longLocal = 'a' * 65;
      final email = '$longLocal@kawalo.co.id';

      expect(
        AppValidator.validateEmail(email),
        contains('Bagian nama email terlalu panjang'),
      );
    });

    test(
      'detects and blocks CRLF, null bytes, and control character injection',
      () {
      expect(
        AppValidator.validateEmail('admin\n@kawalo.co.id'),
        equals('Format email mengandung karakter tidak valid.'),
      );
      expect(
        AppValidator.validateEmail('admin\r\n@kawalo.co.id'),
        equals('Format email mengandung karakter tidak valid.'),
      );
      expect(
        AppValidator.validateEmail('admin\x00@kawalo.co.id'),
        equals('Format email mengandung karakter tidak valid.'),
      );
    });

    test('rejects emails with missing or multiple @ symbols', () {
      expect(
        AppValidator.validateEmail('plainaddress'),
        contains('Format email tidak valid'),
      );
      expect(
        AppValidator.validateEmail('admin@kawalo@co.id'),
        contains('Format email tidak valid'),
      );
      expect(
        AppValidator.validateEmail('@kawalo.co.id'),
        contains('Format email tidak valid'),
      );
      expect(
        AppValidator.validateEmail('admin@'),
        contains('Format email tidak valid'),
      );
    });

    test('rejects consecutive dots and leading/trailing dots in local-part or domain', () {
      expect(
        AppValidator.validateEmail('admin..user@kawalo.co.id'),
        contains('Format email tidak valid (titik tidak boleh berurutan'),
      );
      expect(
        AppValidator.validateEmail('.admin@kawalo.co.id'),
        contains('Format email tidak valid (titik tidak boleh berurutan'),
      );
      expect(
        AppValidator.validateEmail('admin.@kawalo.co.id'),
        contains('Format email tidak valid (titik tidak boleh berurutan'),
      );
      expect(
        AppValidator.validateEmail('admin@kawalo..co.id'),
        contains('Format email tidak valid (titik tidak boleh berurutan'),
      );
    });

    test('rejects invalid domain labels and invalid TLDs', () {
      expect(
        AppValidator.validateEmail('admin@-kawalo.co.id'),
        contains('Format domain email tidak valid'),
      );
      expect(
        AppValidator.validateEmail('admin@kawalo-.co.id'),
        contains('Format domain email tidak valid'),
      );
      expect(
        AppValidator.validateEmail('admin@kawalo.c'),
        contains('Ekstensi domain email (TLD) tidak valid'),
      );
      expect(
        AppValidator.validateEmail('admin@kawalo.123'),
        contains('Ekstensi domain email (TLD) tidak valid'),
      );
    });

    test('accepts valid RFC-compliant emails', () {
      expect(AppValidator.validateEmail('admin@kawalo.co.id'), isNull);
      expect(AppValidator.validateEmail('user.name+tag@domain.com'), isNull);
      expect(AppValidator.validateEmail('support@sub.kawalo.co.id'), isNull);
      expect(AppValidator.validateEmail('personnel_123@kawalo.id'), isNull);
      expect(AppValidator.isValidEmail('admin@kawalo.co.id'), isTrue);
    });
  });

  // ===========================================================================
  // VALIDASI PASSWORD TIPE 1: SUBMIT / LOGIN
  // ===========================================================================
  group('AppValidator.validateLoginPassword', () {
    test('returns error when password is null, empty or whitespace-only', () {
      expect(
        AppValidator.validateLoginPassword(null),
        equals('Harap isi password terlebih dahulu.'),
      );
      expect(
        AppValidator.validateLoginPassword(''),
        equals('Harap isi password terlebih dahulu.'),
      );
      expect(
        AppValidator.validateLoginPassword('   '),
        equals('Harap isi password terlebih dahulu.'),
      );
    });

    test('returns error when password exceeds 128 characters', () {
      final longPassword = 'A' * 129;
      expect(
        AppValidator.validateLoginPassword(longPassword),
        contains('Password melebihi batas panjang maksimum'),
      );
    });

    test('returns null when valid password is provided', () {
      expect(AppValidator.validateLoginPassword('password123'), isNull);
      expect(AppValidator.validatePassword('SecurePass!2024'), isNull);
    });
  });

  // ===========================================================================
  // VALIDASI PASSWORD TIPE 2: CREATE / REGISTER / RENEW (NIST & OWASP)
  // ===========================================================================
  group('AppValidator.validateNewPassword', () {
    test('returns error when new password is null or empty', () {
      expect(
        AppValidator.validateNewPassword(null),
        equals('Harap buat password baru terlebih dahulu.'),
      );
      expect(
        AppValidator.validateNewPassword(''),
        equals('Harap buat password baru terlebih dahulu.'),
      );
    });

    test('returns error when password starts or ends with whitespace', () {
      expect(
        AppValidator.validateNewPassword(' Password123!'),
        equals('Password tidak boleh diawali atau diakhiri dengan spasi.'),
      );
      expect(
        AppValidator.validateNewPassword('Password123! '),
        equals('Password tidak boleh diawali atau diakhiri dengan spasi.'),
      );
    });

    test('returns error when password is less than 8 characters', () {
      expect(
        AppValidator.validateNewPassword('Pass1!'),
        equals('Password minimal harus terdiri dari 8 karakter.'),
      );
    });

    test('returns error when password exceeds 128 characters', () {
      final longPassword = 'P1!${'a' * 130}';
      expect(
        AppValidator.validateNewPassword(longPassword),
        contains('Password terlalu panjang'),
      );
    });

    test(
      'returns error when password is in the common weak passwords blacklist',
      () {
        expect(
          AppValidator.validateNewPassword('password123'),
          contains('Password ini terlalu umum dan mudah ditebak'),
        );
        expect(
          AppValidator.validateNewPassword('12345678'),
          contains('Password ini terlalu umum dan mudah ditebak'),
        );
      },
    );

    test(
      'returns specific guidance when character composition rules are missing',
      () {
        // Missing uppercase
        expect(
          AppValidator.validateNewPassword('password123!'),
          contains('huruf besar (A-Z)'),
        );

        // Missing lowercase
        expect(
          AppValidator.validateNewPassword('PASSWORD123!'),
          contains('huruf kecil (a-z)'),
        );

        // Missing digit
        expect(
          AppValidator.validateNewPassword('Password!@#'),
          contains('angka (0-9)'),
        );

        // Missing special character
        expect(
          AppValidator.validateNewPassword('SecuredPass99'),
          contains(r'simbol khusus (!@#$)'),
        );
      },
    );

    test('returns null when password satisfies all security criteria', () {
      expect(AppValidator.validateNewPassword('K@walo2024Secure!'), isNull);
      expect(AppValidator.validateNewPassword('Admin#Pass99'), isNull);
      expect(AppValidator.validateNewPassword('Super-Secret-2026!'), isNull);
    });
  });

  // ===========================================================================
  // EVALUASI KEKUATAN PASSWORD & CHECKLIST UX
  // ===========================================================================
  group('AppValidator.evaluateNewPassword', () {
    test('accurately calculates checklist booleans and strength score', () {
      final weakResult = AppValidator.evaluateNewPassword('pass');
      expect(weakResult.hasMinLength, isFalse);
      expect(weakResult.hasUppercase, isFalse);
      expect(weakResult.hasDigit, isFalse);
      expect(weakResult.hasSpecialChar, isFalse);
      expect(weakResult.isValid, isFalse);
      expect(weakResult.strengthLevel, equals(PasswordStrength.veryWeak));

      final strongResult =
          AppValidator.evaluateNewPassword('Kawalo#2026Secure!');
      expect(strongResult.hasMinLength, isTrue);
      expect(strongResult.hasUppercase, isTrue);
      expect(strongResult.hasLowercase, isTrue);
      expect(strongResult.hasDigit, isTrue);
      expect(strongResult.hasSpecialChar, isTrue);
      expect(strongResult.hasNoLeadingTrailingSpaces, isTrue);
      expect(strongResult.isNotCommonlyWeak, isTrue);
      expect(strongResult.isValid, isTrue);
      expect(strongResult.strengthScore, equals(1.0));
      expect(strongResult.strengthLevel, equals(PasswordStrength.veryStrong));
    });
  });

  // ===========================================================================
  // VALIDASI KONFIRMASI PASSWORD
  // ===========================================================================
  group('AppValidator.validatePasswordConfirmation', () {
    test('returns error when confirmation is empty or does not match', () {
      expect(
        AppValidator.validatePasswordConfirmation('Secret123!', null),
        equals('Harap konfirmasi password terlebih dahulu.'),
      );
      expect(
        AppValidator.validatePasswordConfirmation('Secret123!', ''),
        equals('Harap konfirmasi password terlebih dahulu.'),
      );
      expect(
        AppValidator.validatePasswordConfirmation('Secret123!', 'Secret123'),
        equals(
          'Konfirmasi password tidak cocok dengan password yang dimasukkan.',
        ),
      );
    });

    test('returns null when confirmation exactly matches password', () {
      expect(
        AppValidator.validatePasswordConfirmation('Secret123!', 'Secret123!'),
        isNull,
      );
    });
  });
}
