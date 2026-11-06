abstract class AppConstants {
  // Timeouts (Mobile REST API Standard)
  /// Batas waktu membuka koneksi socket TCP/TLS ke server (5 detik).
  static const Duration connectTimeout = Duration(seconds: 5);

  /// Batas waktu pengiriman payload data request ke server (15 detik).
  static const Duration sendTimeout = Duration(seconds: 15);

  /// Batas waktu menunggu penerimaan byte respons dari server (20 detik).
  static const Duration receiveTimeout = Duration(seconds: 20);

  // Pagination (Infinite Scroll Standard)
  /// Jumlah data default per halaman untuk infinite scroll list.
  static const int defaultPageSize = 20;

  // Synchronization Feature Keys (Persistence & Offline Sync)
  /// Kunci persistensi waktu sinkronisasi modul data absensi.
  static const String syncKeyAttendance = 'attendance';

  /// Kunci persistensi waktu sinkronisasi modul data informasi.
  static const String syncKeyInformation = 'information';

  /// Kunci persistensi waktu sinkronisasi modul aktifitas operasional.
  static const String syncKeyOperational = 'operational';

  /// Kunci persistensi waktu sinkronisasi modul buku tamu.
  static const String syncKeyGuest = 'guest';

  /// Kunci persistensi waktu sinkronisasi modul laporan insiden.
  static const String syncKeyIncident = 'incident';

  // Cache & Storage Retention
  /// Durasi retensi penyimpanan data lokal sebelum dilakukan pembersihan
  /// (30 hari).
  static const Duration cacheRetentionDuration = Duration(days: 30);
}
