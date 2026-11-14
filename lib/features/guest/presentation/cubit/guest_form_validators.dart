import 'package:kawalo_mobile/core/utils/app_validator.dart';

/// Aturan validasi field formulir tamu; pesan error ditampilkan apa adanya
/// ke pengguna.
class GuestFormValidators {
  const GuestFormValidators._();

  /// Validasi aturan nama tamu (wajib, max 128 karakter).
  static String? validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return AppValidator.validateRequired(trimmed, fieldName: 'Nama tamu');
    }
    if (value.length > 128) {
      return 'Nama tamu maksimal 128 karakter.';
    }
    return null;
  }

  /// Validasi aturan destinasi kunjungan (wajib, max 128 karakter).
  static String? validateDestination(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return AppValidator.validateRequired(trimmed, fieldName: 'Tujuan');
    }
    if (value.length > 128) {
      return 'Tujuan maksimal 128 karakter.';
    }
    return null;
  }

  /// Validasi aturan tipe tamu (wajib, max 64 karakter).
  static String? validateGuestType(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return AppValidator.validateRequired(
        trimmed,
        customMessage: 'Tipe tamu wajib dipilih.',
      );
    }
    if (value.length > 64) {
      return 'Tipe tamu maksimal 64 karakter.';
    }
    return null;
  }

  /// Validasi aturan nomor identitas (wajib jika jenis identitas dipilih,
  /// max 64 karakter).
  static String? validateIdentityNumber(
    String value, {
    required bool isIdentityRequired,
  }) {
    if (!isIdentityRequired) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return AppValidator.validateRequired(
        trimmed,
        customMessage:
            'Nomor identitas wajib diisi jika jenis identitas dipilih.',
      );
    }
    if (value.length > 64) {
      return 'Nomor identitas maksimal 64 karakter.';
    }
    return null;
  }

  /// Validasi aturan nomor tamu / plat kendaraan (opsional, max 32 karakter).
  static String? validateGuestNumber(String value) {
    if (value.length > 32) {
      return 'Nomor tamu maksimal 32 karakter.';
    }
    return null;
  }

  /// Validasi aturan keperluan kunjungan (opsional, max 128 karakter).
  static String? validatePurpose(String value) {
    if (value.length > 128) {
      return 'Keperluan kunjungan maksimal 128 karakter.';
    }
    return null;
  }

  /// Validasi aturan nama tuan rumah (opsional, max 128 karakter).
  static String? validateHostName(String value) {
    if (value.length > 128) {
      return 'Nama tuan rumah maksimal 128 karakter.';
    }
    return null;
  }

  /// Validasi aturan alamat asal (opsional, max 512 karakter).
  static String? validateAddress(String value) {
    if (value.length > 512) {
      return 'Alamat asal maksimal 512 karakter.';
    }
    return null;
  }
}
