/// Tipe kategori feed / informasi yang didukung oleh sistem.
enum InformationFeedType {
  /// Informasi umum.
  general('GENERAL', label: 'Informasi Umum'),

  /// Informasi personil / anggota baru.
  join('JOIN', label: 'Personil Baru'),

  /// Laporan insiden atau kejadian darurat.
  incident('INCIDENT', label: 'Insiden'),

  /// Pengumuman acara atau kegiatan terjadwal.
  event('EVENT', label: 'Acara'),

  /// Informasi kategori lainnya.
  other('OTHER', label: 'Lainnya');

  /// Membuat instance [InformationFeedType].
  const InformationFeedType(this.code, {required this.label});

  /// Kode representasi string di backend / database.
  final String code;

  /// Label deskripsi berbahasa Indonesia.
  final String label;

  /// Daftar semua kode string yang valid untuk validasi sistem.
  static List<String> get allowedCodes =>
      values.map((type) => type.code).toList();

  /// Parse kode string aman tanpa melempar exception (case-insensitive).
  static InformationFeedType? tryFromCode(String? code) {
    if (code == null) return null;
    final upper = code.trim().toUpperCase();
    for (final type in values) {
      if (type.code == upper) return type;
    }
    return null;
  }
}
