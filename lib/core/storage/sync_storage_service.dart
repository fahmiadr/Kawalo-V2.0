import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';

/// Layanan terpusat untuk mengelola persistensi dan cache in-memory waktu
/// sinkronisasi terakhir antar fitur dengan server.
class SyncStorageService {
  /// Membuat instance [SyncStorageService].
  SyncStorageService({SecureStorageService? storageService})
    : _storageService =
          storageService ??
          (_isTestEnvironment ? null : SecureStorageService());

  /// Factory constructor singleton untuk kemudahan akses di Shared Kernel.
  factory SyncStorageService.singleton({SecureStorageService? storageService}) {
    return _instance ??= SyncStorageService(storageService: storageService);
  }

  static bool get _isTestEnvironment {
    try {
      return !kIsWeb && io.Platform.environment.containsKey('FLUTTER_TEST');
    } on Object {
      return false;
    }
  }

  final SecureStorageService? _storageService;
  final Map<String, DateTime> _memoryCache = {};

  static SyncStorageService? _instance;

  /// Instance mock untuk pengujian.
  @visibleForTesting
  static SyncStorageService? get mockInstance => _instance;

  @visibleForTesting
  static set mockInstance(SyncStorageService? service) => _instance = service;

  /// Menyimpan waktu sinkronisasi terakhir untuk [featureKey] baik di memori
  /// maupun di persistent storage.
  Future<void> saveLastSync(String featureKey, DateTime timestamp) async {
    _memoryCache[featureKey] = timestamp;
    try {
      await _storageService
          ?.saveLastSync(featureKey, timestamp)
          .timeout(const Duration(milliseconds: 300));
    } on Object catch (_) {
      // Graceful fallback untuk lingkungan pengujian tanpa secure storage.
    }
  }

  /// Mengambil waktu sinkronisasi terakhir untuk [featureKey].
  /// Mengutamakan pembacaan dari cache in-memory, lalu fallback ke
  /// disk storage.
  Future<DateTime?> getLastSync(String featureKey) async {
    if (_memoryCache.containsKey(featureKey)) {
      return _memoryCache[featureKey];
    }
    try {
      final stored = await _storageService
          ?.getLastSync(featureKey)
          .timeout(const Duration(milliseconds: 300));
      if (stored != null) {
        _memoryCache[featureKey] = stored;
        return stored;
      }
    } on Object catch (_) {
      // Graceful fallback.
    }
    return null;
  }

  /// Mengambil waktu sinkronisasi terakhir untuk [featureKey] secara sinkron
  /// dari cache in-memory tanpa menunggu pembacaan disk storage.
  DateTime? getCachedLastSync(String featureKey) {
    return _memoryCache[featureKey];
  }

  /// Menghasilkan teks greeting tersinkronisasi langsung dari in-memory cache
  /// jika tersedia. Mengembalikan null jika belum ada rekaman di memori.
  String? getCachedGreeting(String featureKey, {DateTime? now}) {
    final lastSync = getCachedLastSync(featureKey);
    if (lastSync == null) return null;
    return AppDateFormat.formatGreeting(lastSync, now: now);
  }

  /// Menyelesaikan greeting awal secara deterministik: mengutamakan
  /// [initialGreeting] jika tidak kosong, atau membaca cache in-memory
  /// dari [featureKey].
  static String resolveInitialGreeting({
    required String initialGreeting,
    required String featureKey,
    SyncStorageService? storageService,
  }) {
    if (initialGreeting.isNotEmpty) return initialGreeting;
    final service = storageService ?? SyncStorageService.singleton();
    return service.getCachedGreeting(featureKey) ?? '';
  }

  /// Menghasilkan teks greeting tersinkronisasi berdasarkan waktu sinkronisasi
  /// terakhir yang tersimpan di storage untuk [featureKey].
  ///
  /// Jika belum pernah ada sinkronisasi, mengembalikan fallback waktu saat ini.
  Future<String> getGreeting(String featureKey, {DateTime? now}) async {
    final lastSync = await getLastSync(featureKey);
    if (lastSync == null) {
      return AppDateFormat.formatGreeting(now ?? DateTime.now(), now: now);
    }
    return AppDateFormat.formatGreeting(lastSync, now: now);
  }

  /// Menghapus cache sinkronisasi untuk [featureKey].
  Future<void> clear(String featureKey) async {
    _memoryCache.remove(featureKey);
    try {
      await _storageService?.clearLastSync(featureKey);
    } on Object catch (_) {
      // Graceful fallback.
    }
  }

  /// Mengosongkan seluruh memori cache dan rekaman storage sinkronisasi.
  Future<void> clearAll() async {
    _memoryCache.clear();
    try {
      await _storageService?.clearAllSyncTimestamps();
    } on Object catch (_) {
      // Graceful fallback.
    }
  }
}
