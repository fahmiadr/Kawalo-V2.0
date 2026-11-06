/// Kategori klasifikasi insiden operasional.
enum IncidentCategory {
  /// Kerusakan fasilitas fisik (misal gerbang, penerangan, lift).
  facility('facility', 'Fasilitas'),

  /// Masalah keamanan dan ketertiban (misal penyusup, kehilangan).
  security('security', 'Keamanan'),

  /// Potensi bahaya keselamatan (misal tumpahan licin, kabel terbuka).
  hazard('hazard', 'Bahaya'),

  /// Kejadian umum lainnya.
  general('general', 'Umum');

  const IncidentCategory(this.value, this.displayName);

  /// Nilai identifier wire backend.
  final String value;

  /// Label yang ramah ditampilkan ke pengguna.
  final String displayName;

  /// Memetakan string API ke [IncidentCategory], defaulting ke [general].
  static IncidentCategory fromString(String? raw) {
    if (raw == null) return IncidentCategory.general;
    final lower = raw.trim().toLowerCase();
    for (final category in values) {
      if (category.value == lower) return category;
    }
    return IncidentCategory.general;
  }
}
