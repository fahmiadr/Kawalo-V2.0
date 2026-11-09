/// Enum tingkat kekuatan kata sandi untuk visual feedback meter
enum PasswordStrength {
  /// Sangat Lemah (< 40%)
  veryWeak,

  /// Lemah (40% - 59%)
  weak,

  /// Cukup / Sedang (60% - 79%)
  medium,

  /// Kuat (80% - 99%)
  strong,

  /// Sangat Kuat (100%)
  veryStrong,
}

/// Model hasil evaluasi kriteria keamanan kata sandi baru untuk kebutuhan
/// checklist UX dan meter kekuatan kata sandi (Password Strength Indicator).
class PasswordValidationResult {
  /// Membuat instance [PasswordValidationResult].
  const PasswordValidationResult({
    required this.hasMinLength,
    required this.hasMaxLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecialChar,
    required this.hasNoLeadingTrailingSpaces,
    required this.isNotCommonlyWeak,
  });

  /// Memenuhi batas panjang minimal 8 karakter (NIST SP 800-63B)
  final bool hasMinLength;

  /// Memenuhi batas panjang maksimum 128 karakter (Mitigasi DoS)
  final bool hasMaxLength;

  /// Mengandung minimal 1 huruf besar (A-Z)
  final bool hasUppercase;

  /// Mengandung minimal 1 huruf kecil (a-z)
  final bool hasLowercase;

  /// Mengandung minimal 1 angka (0-9)
  final bool hasDigit;

  /// Mengandung minimal 1 simbol khusus / karakter unik
  final bool hasSpecialChar;

  /// Tidak diawali atau diakhiri dengan karakter spasi
  final bool hasNoLeadingTrailingSpaces;

  /// Tidak termasuk dalam daftar kata sandi umum yang sangat lemah
  final bool isNotCommonlyWeak;

  /// Apakah seluruh kriteria keamanan esensial telah terpenuhi
  bool get isValid =>
      hasMinLength &&
      hasMaxLength &&
      hasUppercase &&
      hasLowercase &&
      hasDigit &&
      hasSpecialChar &&
      hasNoLeadingTrailingSpaces &&
      isNotCommonlyWeak;

  /// Skor kekuatan kata sandi dalam rentang `0.0` sampai `1.0`
  double get strengthScore {
    var score = 0;
    if (hasMinLength) score += 20;
    if (hasUppercase) score += 15;
    if (hasLowercase) score += 15;
    if (hasDigit) score += 15;
    if (hasSpecialChar) score += 15;
    if (hasNoLeadingTrailingSpaces) score += 10;
    if (isNotCommonlyWeak) score += 10;

    return (score / 100.0).clamp(0.0, 1.0);
  }

  /// Kategori kekuatan kata sandi berdasarkan skor
  PasswordStrength get strengthLevel {
    final score = strengthScore;
    if (score < 0.40) return PasswordStrength.veryWeak;
    if (score < 0.60) return PasswordStrength.weak;
    if (score < 0.80) return PasswordStrength.medium;
    if (score < 0.95) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }
}

/// Utility terpadu untuk validasi input pengguna (Email, Password, Input Form)
/// dengan standar keamanan NIST SP 800-63B, OWASP ASVS, dan UX yang ramah.
class AppValidator {
  const AppValidator._();

  // ===========================================================================
  // 0. VALIDASI WAJIB DIISI (Generic Required Field)
  // ===========================================================================

  /// Memvalidasi bahwa field tidak kosong (wajib diisi).
  ///
  /// Mendukung pesan kustom melalui [customMessage] atau pembuatan pesan
  /// otomatis melalui [fieldName] (misalnya `'Nama tamu'` →
  /// `'Nama tamu wajib diisi'`).
  ///
  /// Mengembalikan `null` jika valid, atau string pesan error jika kosong.
  static String? validateRequired(
    String? value, {
    String? fieldName,
    String? customMessage,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (customMessage != null) {
        return customMessage;
      }
      if (fieldName != null) {
        return '$fieldName wajib diisi';
      }
      return 'Field ini wajib diisi';
    }
    return null;
  }

  // ===========================================================================
  // 1. VALIDASI EMAIL (RFC 5322 & ReDoS Protection)
  // ===========================================================================

  /// Batas panjang maksimum email sesuai RFC 5321
  static const int maxEmailLength = 254;

  /// Batas panjang maksimum local-part (sebelum '@')
  static const int maxLocalPartLength = 64;

  /// Batas panjang maksimum domain label (antara dua titik)
  static const int maxDomainLabelLength = 63;

  /// Batas panjang minimum password baru sesuai NIST SP 800-63B
  static const int minPasswordLength = 8;

  /// Batas panjang maksimum password untuk mitigasi DoS
  static const int maxPasswordLength = 128;

  /// Regex RFC 5322 compliant & W3C HTML5 Standard yang aman dari ReDoS
  /// (Regular Expression Denial of Service) karena linier O(N).
  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  /// Regex karakter huruf besar
  static final RegExp _uppercaseRegex = RegExp('[A-Z]');

  /// Regex karakter huruf kecil
  static final RegExp _lowercaseRegex = RegExp('[a-z]');

  /// Regex karakter angka
  static final RegExp _digitRegex = RegExp('[0-9]');

  /// Regex karakter simbol / spesial yang diizinkan NIST & OWASP
  static final RegExp _specialCharRegex = RegExp(
    r'[!@#$%^&*(),.?":{}|<>\-_+=\[\]\\/~`]',
  );

  /// Daftar pola kata sandi umum yang sangat lemah
  static const Set<String> _commonlyWeakPasswords = {
    '12345678',
    '123456789',
    'password',
    'password123',
    'admin123',
    'admin1234',
    'qwerty123',
    'kawalo123',
    'kawalo2024',
    'kawalo2025',
    'kawalo2026',
    'indonesia123',
    'rahasia123',
    'bismillah123',
  };

  /// Memvalidasi format email secara komprehensif.
  ///
  /// Mengembalikan `null` jika valid, atau string pesan error jika tidak valid.
  static String? validateEmail(String? value) {
    final requiredError = validateRequired(
      value,
      customMessage: 'Harap isi email terlebih dahulu.',
    );
    if (requiredError != null || value == null) {
      return requiredError;
    }

    final trimmed = value.trim();

    // 1. Cek Batas Panjang Maksimum (RFC 5321)
    if (trimmed.length > maxEmailLength) {
      return 'Email melebihi batas panjang maksimum '
          '($maxEmailLength karakter).';
    }

    // 2. Cek Karakter Kontrol & Whitespace Tersembunyi
    // (Mitigasi CRLF Injection)
    if (trimmed.contains('\n') ||
        trimmed.contains('\r') ||
        trimmed.contains('\t') ||
        trimmed.contains('\x00')) {
      return 'Format email mengandung karakter tidak valid.';
    }

    // 3. Cek Pembagian Bagian Local dan Domain
    final atIndex = trimmed.indexOf('@');
    final lastAtIndex = trimmed.lastIndexOf('@');

    if (atIndex <= 0 ||
        atIndex != lastAtIndex ||
        atIndex == trimmed.length - 1) {
      return 'Format email tidak valid. Gunakan format nama@domain.com.';
    }

    final localPart = trimmed.substring(0, atIndex);
    final domainPart = trimmed.substring(atIndex + 1);

    if (localPart.length > maxLocalPartLength) {
      return 'Bagian nama email terlalu panjang '
          '(maksimal $maxLocalPartLength karakter).';
    }

    // 4. Cek Titik di Local-part dan Domain (RFC 5322 melarang double dots)
    if (localPart.startsWith('.') ||
        localPart.endsWith('.') ||
        localPart.contains('..') ||
        domainPart.startsWith('.') ||
        domainPart.endsWith('.') ||
        domainPart.contains('..')) {
      return 'Format email tidak valid (titik tidak boleh berurutan '
          'atau di awal/akhir).';
    }

    // 5. Cek Label Domain dan TLD
    final domainLabels = domainPart.split('.');
    if (domainLabels.length < 2) {
      return 'Domain email tidak lengkap. Gunakan format nama@domain.com.';
    }

    for (final label in domainLabels) {
      if (label.isEmpty ||
          label.length > maxDomainLabelLength ||
          label.startsWith('-') ||
          label.endsWith('-')) {
        return 'Format domain email tidak valid.';
      }
    }

    final tld = domainLabels.last;
    if (tld.length < 2 || RegExp(r'^[0-9]+$').hasMatch(tld)) {
      return 'Ekstensi domain email (TLD) tidak valid.';
    }

    // 6. Evaluasi Regex Linier
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Format email tidak valid. Gunakan format nama@domain.com.';
    }

    return null;
  }

  /// Pengecekan cepat apakah email valid secara format
  static bool isValidEmail(String? value) {
    return validateEmail(value) == null;
  }

  // ===========================================================================
  // 2. VALIDASI PASSWORD TIPE 1: SUBMIT / LOGIN
  // ===========================================================================

  /// Validasi password untuk form login/masuk.
  ///
  /// Memastikan field terisi dan dalam batas panjang wajar.
  static String? validateLoginPassword(String? value) {
    final requiredError = validateRequired(
      value,
      customMessage: 'Harap isi password terlebih dahulu.',
    );
    if (requiredError != null || value == null) {
      return requiredError;
    }
    if (value.length > maxPasswordLength) {
      return 'Password melebihi batas panjang maksimum '
          '($maxPasswordLength karakter).';
    }
    return null;
  }

  /// Alias dari [validateLoginPassword] untuk kompatibilitas form umum
  static String? validatePassword(String? value) =>
      validateLoginPassword(value);

  // ===========================================================================
  // 3. VALIDASI PASSWORD TIPE 2: CREATE / REGISTER / RENEW (NIST & OWASP)
  // ===========================================================================

  /// Melakukan evaluasi kriteria password secara menyeluruh dan mengembalikan
  /// struktur [PasswordValidationResult] untuk visual feedback.
  static PasswordValidationResult evaluateNewPassword(String? value) {
    if (value == null || validateRequired(value) != null) {
      return const PasswordValidationResult(
        hasMinLength: false,
        hasMaxLength: true,
        hasUppercase: false,
        hasLowercase: false,
        hasDigit: false,
        hasSpecialChar: false,
        hasNoLeadingTrailingSpaces: true,
        isNotCommonlyWeak: false,
      );
    }

    final hasNoSpaces =
        value == value.trim() && !value.startsWith(' ') && !value.endsWith(' ');
    final normalized = value.trim().toLowerCase();
    final isNotWeak = !_commonlyWeakPasswords.contains(normalized);

    return PasswordValidationResult(
      hasMinLength: value.length >= minPasswordLength,
      hasMaxLength: value.length <= maxPasswordLength,
      hasUppercase: _uppercaseRegex.hasMatch(value),
      hasLowercase: _lowercaseRegex.hasMatch(value),
      hasDigit: _digitRegex.hasMatch(value),
      hasSpecialChar: _specialCharRegex.hasMatch(value),
      hasNoLeadingTrailingSpaces: hasNoSpaces,
      isNotCommonlyWeak: isNotWeak,
    );
  }

  /// Validasi password baru saat pendaftaran akun (Register), reset password,
  /// atau pembaharuan kata sandi (Renew).
  ///
  /// Menggabungkan standar **NIST SP 800-63B** & **OWASP ASVS** dengan pesan UX
  /// yang jelas, ramah, dan berorientasi pada tindakan langsung.
  static String? validateNewPassword(String? value) {
    final requiredError = validateRequired(
      value,
      customMessage: 'Harap buat password baru terlebih dahulu.',
    );
    if (requiredError != null || value == null) {
      return requiredError;
    }

    if (value.startsWith(' ') || value.endsWith(' ')) {
      return 'Password tidak boleh diawali atau diakhiri dengan spasi.';
    }

    if (value.length < minPasswordLength) {
      return 'Password minimal harus terdiri dari $minPasswordLength karakter.';
    }

    if (value.length > maxPasswordLength) {
      return 'Password terlalu panjang (maksimal $maxPasswordLength karakter).';
    }

    final evaluation = evaluateNewPassword(value);

    if (!evaluation.isNotCommonlyWeak) {
      return 'Password ini terlalu umum dan mudah ditebak. '
          'Buat password yang lebih unik.';
    }

    // Pengecekan komposisi karakter (Huruf Besar, Huruf Kecil, Angka, Simbol)
    final missingRules = <String>[];
    if (!evaluation.hasUppercase) missingRules.add('huruf besar (A-Z)');
    if (!evaluation.hasLowercase) missingRules.add('huruf kecil (a-z)');
    if (!evaluation.hasDigit) missingRules.add('angka (0-9)');
    if (!evaluation.hasSpecialChar) missingRules.add(r'simbol khusus (!@#$)');

    if (missingRules.isNotEmpty) {
      return 'Password harus memuat minimal 1 ${missingRules.join(', 1 ')}.';
    }

    return null;
  }

  /// Validasi konfirmasi password (memastikan input konfirmasi cocok).
  static String? validatePasswordConfirmation(
    String? password,
    String? confirmation,
  ) {
    if (confirmation == null || confirmation.isEmpty) {
      return 'Harap konfirmasi password terlebih dahulu.';
    }

    if (password != confirmation) {
      return 'Konfirmasi password tidak cocok '
          'dengan password yang dimasukkan.';
    }

    return null;
  }
}
