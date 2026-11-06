/// Tipe pelanggaran keamanan perangkat yang memicu penguncian aplikasi
/// (Strict Lockdown).
enum SecurityViolationType {
  /// Perangkat terindikasi telah di-root (Android) atau di-jailbreak (iOS).
  rootOrJailbreak,

  /// Penggunaan lokasi palsu (Mock Location / Fake GPS provider) terdeteksi.
  mockLocation,

  /// Aplikasi diinstal di luar toko aplikasi resmi (Google Play / App Store).
  unofficialStore,
}
