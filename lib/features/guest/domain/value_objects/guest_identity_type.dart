/// Jenis kartu identitas tamu yang didukung oleh sistem.
enum GuestIdentityType {
  /// Kartu Tanda Penduduk.
  ktp('KTP', label: 'KTP'),

  /// Surat Izin Mengemudi.
  sim('SIM', label: 'SIM'),

  /// Paspor.
  paspor('PASPOR', label: 'Paspor'),

  /// Jenis identitas lainnya.
  lainnya('LAINNYA', label: 'Lainnya');

  /// Membuat instance [GuestIdentityType].
  const GuestIdentityType(this.code, {required this.label});

  /// Kode representasi string di backend / database.
  final String code;

  /// Label deskripsi kartu identitas.
  final String label;

  /// Daftar seluruh kode identitas valid untuk validasi sistem.
  static List<String> get allowedCodes =>
      values.map((type) => type.code).toList();

  /// Parse kode string secara aman tanpa melempar exception (case-insensitive).
  static GuestIdentityType? tryFromCode(String? code) {
    if (code == null) return null;
    final upper = code.trim().toUpperCase();
    for (final type in values) {
      if (type.code == upper) return type;
    }
    return null;
  }
}
