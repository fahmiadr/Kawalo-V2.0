/// Status hasil eksekusi operasi pemanggilan data (fetch/query)
/// pada lapisan State Management (BLoC/Cubit).
enum AppFetchResult {
  /// Data berhasil dimuat segar dari server remote.
  success,

  /// Data disajikan dari cache lokal (offline atau fallback gangguan jaringan).
  cachedFallback,

  /// Terjadi kegagalan saat memuat data.
  failure,

  /// Permintaan dibatalkan atau digantikan (superseded) oleh request baru.
  cancelled,
}
