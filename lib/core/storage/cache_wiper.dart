import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';

/// Kontrak untuk komponen penyimpanan lokal yang mendukung pembersihan cache.
abstract interface class CacheWipeable {
  /// Mengosongkan seluruh cache data yang dikelola.
  Future<void> clearCache();
}

/// Koordinator pembersihan cache lintas modul untuk data lokal (Isar)
/// dan timestamp sinkronisasi (SecureStorage / SyncStorageService).
///
/// Bertujuan mencegah kebocoran data (data leakage) antar pengguna atau grup
/// berbeda pada perangkat yang sama.
///
/// Dipanggil pada seluruh titik transisi identitas pengguna:
/// - Logout eksplisit (dikoordinasikan via `LogoutOrchestrator`)
/// - Login sukses (safety-net pembersihan data lama di `LoginUseCase`)
/// - Switch group sukses (safety-net di `SwitchGroupUseCase`)
class CacheWiper {
  /// Membuat instance [CacheWiper].
  CacheWiper({
    List<CacheWipeable> wipeables = const [],
    this.secureStorageService,
    this.syncStorageService,
  }) : _wipeables = List.of(wipeables);

  final List<CacheWipeable> _wipeables;

  /// Layanan secure storage untuk membersihkan timestamp sinkronisasi.
  final SecureStorageService? secureStorageService;

  /// Layanan sinkronisasi terpusat untuk membersihkan cache sinkronisasi.
  final SyncStorageService? syncStorageService;

  /// Daftar komponen [CacheWipeable] yang terdaftar.
  List<CacheWipeable> get wipeables => List.unmodifiable(_wipeables);

  /// Mendaftarkan [CacheWipeable] baru ke dalam koordinator.
  void register(CacheWipeable wipeable) {
    _wipeables.add(wipeable);
  }

  /// Menghapus seluruh feature cache dan mereset timestamp sinkronisasi
  /// secara paralel.
  ///
  /// Bersifat best-effort: kegagalan salah satu pembersihan tidak akan
  /// membatalkan atau menghentikan pembersihan komponen lainnya.
  Future<void> wipeAll() async {
    final tasks = <Future<void>>[];

    for (final wipeable in _wipeables) {
      tasks.add(_safeRun(wipeable.clearCache));
    }

    if (syncStorageService != null) {
      tasks.add(_safeRun(syncStorageService!.clearAll));
    } else if (secureStorageService != null) {
      tasks.add(_safeRun(secureStorageService!.clearAllSyncTimestamps));
    }

    await Future.wait(tasks);
  }

  static Future<void> _safeRun(Future<void> Function() fn) async {
    try {
      await fn();
    } on Object catch (_) {
      // Best-effort: kegagalan parsial diabaikan agar transisi aman.
    }
  }
}
