import 'package:kawalo_mobile/core/utils/app_validator.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/information_feed_type.dart';

/// Aturan validasi field formulir informasi; pesan error ditampilkan apa
/// adanya ke pengguna.
class InformationFormValidators {
  const InformationFormValidators._();

  /// Validasi aturan judul informasi (wajib, max 128 karakter).
  static String? validateTitle(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return AppValidator.validateRequired(trimmed, fieldName: 'Judul');
    }
    if (value.length > 128) {
      return 'Judul maksimal 128 karakter.';
    }
    return null;
  }

  /// Validasi aturan deskripsi informasi (max 1024 karakter).
  static String? validateText(String value) {
    if (value.length > 1024) {
      return 'Deskripsi informasi maksimal 1024 karakter.';
    }
    return null;
  }

  /// Validasi kategori postingan.
  static String? validateFeedType(String value) {
    final upper = value.trim().toUpperCase();
    if (!InformationFeedType.allowedCodes.contains(upper)) {
      return 'Kategori informasi tidak valid.';
    }
    return null;
  }

  /// Validasi batas panjang tautan berkas lampiran.
  static String? validateFeedFile(String value) {
    if (value.length > 2048) {
      return 'Tautan berkas maksimal 2048 karakter.';
    }
    return null;
  }

  /// Validasi nama lokasi kejadian (max 128 karakter).
  static String? validateEventLocation(String value) {
    if (value.length > 128) {
      return 'Nama lokasi maksimal 128 karakter.';
    }
    return null;
  }

  /// Validasi angka koordinat garis lintang GPS.
  static String? validateGlat(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length > 32) {
      return 'Panjang latitude maksimal 32 karakter.';
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed < -90.0 || parsed > 90.0) {
      return 'Latitude harus berupa angka valid antara -90 dan 90.';
    }
    return null;
  }

  /// Validasi angka koordinat garis bujur GPS.
  static String? validateGlong(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length > 32) {
      return 'Panjang longitude maksimal 32 karakter.';
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed < -180.0 || parsed > 180.0) {
      return 'Longitude harus berupa angka valid antara -180 dan 180.';
    }
    return null;
  }

  /// Validasi pasangan koordinat saat submit: masing-masing field divalidasi,
  /// dan salah satunya wajib diisi jika yang lain sudah ditentukan.
  static ({String? glat, String? glong}) validateCoordinates(
    String glat,
    String glong,
  ) {
    final hasGlat = glat.trim().isNotEmpty;
    final hasGlong = glong.trim().isNotEmpty;
    var glatErr = validateGlat(glat);
    var glongErr = validateGlong(glong);
    if (hasGlat != hasGlong) {
      if (!hasGlat) {
        glatErr ??= 'Latitude wajib diisi jika longitude ditentukan.';
      }
      if (!hasGlong) {
        glongErr ??= 'Longitude wajib diisi jika latitude ditentukan.';
      }
    }
    return (glat: glatErr, glong: glongErr);
  }
}
