/// Utility converter terpusat untuk menghasilkan Display Getters pada entitas
/// dan model aplikasi Kawalo.
///
/// Menyediakan fallback indicator standar (em-dash `—`, tanda hubung `-`,
/// atau teks penjelasan eksplisit) untuk data bernilai `null` atau kosong
/// akibat pembatasan ACL maupun data opsional backend.
class AppDisplayFormatter {
  const AppDisplayFormatter._();

  /// Indikator em-dash standar Material Design untuk data tidak terisi/kosong.
  static const String emDash = '—';

  /// Indikator tanda hubung ringkas (*hyphen*).
  static const String dash = '-';

  /// Indikator teks eksplisit untuk data yang dibatasi hak akses ACL/kosong.
  static const String notAvailable = 'Tidak tersedia';

  /// Indikator teks eksplisit untuk konfigurasi/jadwal yang belum ditentukan.
  static const String notSet = 'Belum diatur';

  /// Indikator teks eksplisit untuk rekaman atau log yang tidak tercatat.
  static const String unrecorded = 'Tidak tercatat';

  /// Memeriksa apakah suatu string bernilai `null` atau hanya berisi spasi.
  static bool isBlank(String? value) =>
      value == null || value.trim().isEmpty;

  /// Mengonversi nilai teks mentah menjadi string tampilan (*display*) aman
  /// dengan fallback em-dash (`—`) atau [fallback] pilihan.
  static String toDisplay(
    String? value, {
    String fallback = emDash,
  }) {
    if (isBlank(value)) return fallback;
    return value!.trim();
  }

  /// Mengonversi nilai teks mentah dengan fallback eksplisit
  /// `"Tidak tersedia"`.
  static String toDisplayNotAvailable(String? value) =>
      toDisplay(value, fallback: notAvailable);

  /// Mengonversi nilai teks mentah dengan fallback eksplisit `"Belum diatur"`.
  static String toDisplayNotSet(String? value) =>
      toDisplay(value, fallback: notSet);

  /// Mengonversi nilai teks mentah dengan fallback eksplisit
  /// `"Tidak tercatat"`.
  static String toDisplayUnrecorded(String? value) =>
      toDisplay(value, fallback: unrecorded);

  /// Mengonversi nilai teks mentah dengan fallback teks kustom
  /// [explicitFallback].
  static String toDisplayExplicit(
    String? value,
    String explicitFallback,
  ) =>
      toDisplay(value, fallback: explicitFallback);

  /// Mengonversi nilai teks mentah menggunakan fungsi [formatter] kustom jika
  /// tidak kosong, atau mengembalikan [fallback] jika kosong/null.
  static String toDisplayFormat(
    String? value,
    String Function(String nonBlankValue) formatter, {
    String fallback = emDash,
  }) {
    if (isBlank(value)) return fallback;
    return formatter(value!.trim());
  }
}

/// Ekstensi pembuat display getter langsung pada data mentah [String?].
extension DisplayGetterExtension on String? {
  /// Mengonversi data mentah ke representasi display dengan fallback em-dash
  /// (`—`) atau [fallback] kustom.
  String toDisplay({String fallback = AppDisplayFormatter.emDash}) =>
      AppDisplayFormatter.toDisplay(this, fallback: fallback);

  /// Mengonversi data mentah dengan fallback teks eksplisit
  /// `"Tidak tersedia"`.
  String toDisplayNotAvailable() =>
      AppDisplayFormatter.toDisplayNotAvailable(this);

  /// Mengonversi data mentah dengan fallback teks eksplisit `"Belum diatur"`.
  String toDisplayNotSet() =>
      AppDisplayFormatter.toDisplayNotSet(this);

  /// Mengonversi data mentah dengan fallback teks eksplisit
  /// `"Tidak tercatat"`.
  String toDisplayUnrecorded() =>
      AppDisplayFormatter.toDisplayUnrecorded(this);

  /// Mengonversi data mentah dengan fallback teks kustom [explicitFallback].
  String toDisplayExplicit(String explicitFallback) =>
      AppDisplayFormatter.toDisplayExplicit(this, explicitFallback);

  /// Mengonversi data mentah menggunakan fungsi [formatter] khusus jika
  /// tidak kosong, atau mengembalikan [fallback] jika kosong/null.
  String toDisplayFormat(
    String Function(String value) formatter, {
    String fallback = AppDisplayFormatter.emDash,
  }) =>
      AppDisplayFormatter.toDisplayFormat(this, formatter, fallback: fallback);

  /// Memeriksa apakah string bernilai `null` atau kosong.
  bool get isNullOrBlank => AppDisplayFormatter.isBlank(this);
}
