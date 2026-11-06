/// Utilitas sanitasi data terpusat untuk Anti-Corruption Layer (ACL).
///
/// Membersihkan payload string kotor, data null/kosong/N/A, email,
/// tanggal epoch, bilangan bulat, koordinat GPS, role pengguna,
/// rentang waktu shift, dan daftar string sebelum dipetakan ke entity
/// atau model penyimpanan lokal.
abstract final class AppSanitizer {
  const AppSanitizer._();

  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  /// Membersihkan string kotor.
  ///
  /// Mengembalikan `null` jika string bernilai `null`, kosong, hanya berisi
  /// spasi, bernilai literal `'N/A'`, `'null'`, atau `'-'`.
  static String? cleanString(String? val) {
    if (val == null) return null;
    final trimmed = val.trim();
    if (trimmed.isEmpty ||
        trimmed == 'N/A' ||
        trimmed == 'null' ||
        trimmed == '-') {
      return null;
    }
    return trimmed;
  }

  /// Membersihkan dan menormalisasi string alamat email.
  ///
  /// Mengembalikan string huruf kecil yang telah di-trim jika valid,
  /// atau `null` jika string kosong, placeholder, atau format tidak valid.
  static String? cleanEmail(String? val) {
    final cleaned = cleanString(val);
    if (cleaned == null) return null;
    if (_emailRegex.hasMatch(cleaned)) {
      return cleaned.toLowerCase();
    }
    return null;
  }

  /// Membersihkan dan menormalisasi nomor telepon internasional (E.164).
  ///
  /// Mengizinkan prefix '+' jika ada di awal, membuang seluruh karakter
  /// non-angka, dan memastikan terdapat setidaknya 1 angka.
  /// Mengembalikan `null` jika string bernilai null, kosong, placeholder,
  /// atau tidak mengandung angka.
  static String? cleanPhone(String? val) {
    final cleaned = cleanString(val);
    if (cleaned == null) return null;
    final hasPlusPrefix = cleaned.startsWith('+');
    final digitsOnly = cleaned.replaceAll(RegExp('[^0-9]'), '');
    if (digitsOnly.isEmpty) return null;
    return hasPlusPrefix ? '+$digitsOnly' : digitsOnly;
  }

  /// Membersihkan dan menormalisasi role pengguna.
  ///
  /// Mengembalikan huruf besar yang telah di-trim (e.g. `'ADMIN'`, `'GUARD'`)
  /// tanpa fallback dummy. Mengembalikan `null` bila kosong atau tidak valid.
  static String? cleanRole(String? val) {
    final cleaned = cleanString(val);
    if (cleaned == null) return null;
    return cleaned.toUpperCase();
  }

  /// Membersihkan tanggal dalam format string.
  ///
  /// Mengabaikan tanggal epoch default database legacy (`'0000-00-00'` atau
  /// `'1970-01-01'`).
  static String? cleanDate(String? val) {
    final cleaned = cleanString(val);
    if (cleaned == null) return null;
    if (cleaned.startsWith('0000-00-00') || cleaned.startsWith('1970-01-01')) {
      return null;
    }
    return cleaned;
  }

  /// Membersihkan rentang jam kerja shift (misal: "07:00 - 15:00").
  ///
  /// Mengabaikan string default dummy `'00:00:00'` atau `'00:00'`.
  static String? cleanTimeWindow(String? val) {
    final cleaned = cleanString(val);
    if (cleaned == null || cleaned == '00:00:00' || cleaned == '00:00') {
      return null;
    }
    return cleaned;
  }

  /// Membersihkan nilai bilangan bulat (integer).
  ///
  /// Menerima input bertipe [Object?] ([num], [String], atau `null`).
  /// Memotong komponen pecahan desimal jika bertipe float/double,
  /// serta mengabaikan NaN, Infinity, atau string kotor dengan mengembalikan
  /// `null` tanpa fallback.
  static int? cleanInteger(Object? val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is double) {
      if (val.isNaN || val.isInfinite) return null;
      return val.truncate();
    }
    if (val is String) {
      final cleaned = cleanString(val);
      if (cleaned == null) return null;
      final parsedInt = int.tryParse(cleaned);
      if (parsedInt != null) return parsedInt;
      final parsedDouble = double.tryParse(cleaned);
      if (parsedDouble != null &&
          !parsedDouble.isNaN &&
          !parsedDouble.isInfinite) {
        return parsedDouble.truncate();
      }
    }
    return null;
  }

  /// Membersihkan koordinat GPS numerik dengan rentang batas yang ditentukan.
  ///
  /// Mengabaikan nilai `'0'`, `'0.0'`, `'0.000000'`, nilai di luar rentang
  /// [min] s/d [max], atau string yang tidak dapat diparsing.
  static String? cleanCoordinate(
    String? val, {
    double min = -180,
    double max = 180,
  }) {
    final cleaned = cleanString(val);
    if (cleaned == null) return null;
    if (cleaned == '0' || cleaned == '0.0' || cleaned == '0.000000') {
      return null;
    }
    final parsed = double.tryParse(cleaned);
    if (parsed == null) return null;
    if (parsed < min || parsed > max) return null;
    return cleaned;
  }

  /// Membersihkan koordinat GPS numerik dan mem-parsing ke tipe [double].
  static double? cleanCoordinateDouble(
    String? val, {
    double min = -180,
    double max = 180,
  }) {
    final cleaned = cleanString(val);
    if (cleaned == null) return null;
    if (cleaned == '0' || cleaned == '0.0' || cleaned == '0.000000') {
      return null;
    }
    final parsed = double.tryParse(cleaned);
    if (parsed == null) return null;
    if (parsed < min || parsed > max) return null;
    return parsed;
  }

  /// Membersihkan koordinat garis lintang GPS (Latitude).
  ///
  /// Rentang valid geografis bumi adalah -90 s/d 90 derajat.
  static String? cleanLatitude(String? val) =>
      cleanCoordinate(val, min: -90, max: 90);

  /// Membersihkan koordinat garis bujur GPS (Longitude).
  ///
  /// Rentang valid geografis bumi adalah -180 s/d 180 derajat.
  static String? cleanLongitude(String? val) => cleanCoordinate(val);

  /// Membersihkan koordinat garis lintang GPS (Latitude) ke tipe [double].
  static double? cleanLatitudeDouble(String? val) =>
      cleanCoordinateDouble(val, min: -90, max: 90);

  /// Membersihkan koordinat garis bujur GPS (Longitude) ke tipe [double].
  static double? cleanLongitudeDouble(String? val) =>
      cleanCoordinateDouble(val);

  /// Memeriksa apakah nilai garis lintang (latitude) valid secara fisik.
  ///
  /// Garis lintang valid berada pada rentang -90 s/d 90 derajat,
  /// bukan null, bukan NaN, dan bukan Infinite. Nilai 0.0 dianggap valid.
  static bool isValidLatitude(num? lat) {
    if (lat == null || lat.isNaN || lat.isInfinite) return false;
    return lat >= -90.0 && lat <= 90.0;
  }

  /// Memeriksa apakah nilai garis bujur (longitude) valid secara fisik.
  ///
  /// Garis bujur valid berada pada rentang -180 s/d 180 derajat,
  /// bukan null, bukan NaN, dan bukan Infinite. Nilai 0.0 dianggap valid.
  static bool isValidLongitude(num? lng) {
    if (lng == null || lng.isNaN || lng.isInfinite) return false;
    return lng >= -180.0 && lng <= 180.0;
  }

  /// Memeriksa apakah koordinat latitude dan longitude valid secara fisik.
  static bool isValidCoordinates({
    required num? latitude,
    required num? longitude,
  }) =>
      isValidLatitude(latitude) && isValidLongitude(longitude);

  /// Membersihkan daftar string dengan membuang elemen kosong, `'N/A'`,
  /// `'null'`, atau `'-'` serta mengembalikan list fixed-length
  /// (`growable: false`).
  static List<String> cleanStringList(List<String>? list) {
    if (list == null || list.isEmpty) return const [];
    return list
        .map(cleanString)
        .whereType<String>()
        .toList(growable: false);
  }

  static final RegExp _filePathRegex = RegExp(
    '(?:/[a-zA-Z0-9_.-]+){2,}|'
    r'(?:[a-zA-Z]:\\[a-zA-Z0-9_.\-\\ ]+)',
  );

  /// Menyamarkan absolute path filesystem dari string pesan galat menjadi
  /// `[path]` demi mencegah Information Disclosure di lingkungan produksi.
  static String stripFilePaths(String? input) {
    if (input == null || input.isEmpty) return '';
    return input.replaceAll(_filePathRegex, '[path]');
  }
}
