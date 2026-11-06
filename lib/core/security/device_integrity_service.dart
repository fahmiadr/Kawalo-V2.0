import 'package:flutter/foundation.dart';
import 'package:jailbreak_root_detection/jailbreak_root_detection.dart';
import 'package:kawalo_mobile/core/config/env_config.dart';
import 'package:kawalo_mobile/core/security/models/security_violation_type.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Kontrak platform untuk pengujian dan pembacaan integritas perangkat
/// secara modular.
abstract interface class DeviceIntegrityPlatform {
  /// Memeriksa status root (Android) atau jailbreak (iOS).
  Future<bool> isJailbroken();

  /// Mengambil nama paket penginstal aplikasi (*installer store*).
  Future<String?> getInstallerStore();

  /// Mengambil tanda tangan digital biner (SHA-256 build signature).
  Future<String> getBuildSignature();

  /// Mengidentifikasi platform sistem operasi saat ini.
  TargetPlatform get targetPlatform;
}

/// Implementasi default platform integritas perangkat menggunakan plugin
/// resmi platform channel.
final class DefaultDeviceIntegrityPlatform
    implements DeviceIntegrityPlatform {
  const DefaultDeviceIntegrityPlatform();

  @override
  Future<bool> isJailbroken() => JailbreakRootDetection.instance.isJailBroken;

  @override
  Future<String?> getInstallerStore() async {
    final info = await PackageInfo.fromPlatform();
    return info.installerStore;
  }

  @override
  Future<String> getBuildSignature() async {
    final info = await PackageInfo.fromPlatform();
    return info.buildSignature;
  }

  @override
  TargetPlatform get targetPlatform => defaultTargetPlatform;
}

/// Layanan deteksi integritas biner dan perangkat (Root, Jailbreak,
/// Anti-Tamper, dan Asal Instalasi Toko Resmi).
abstract final class DeviceIntegrityService {
  const DeviceIntegrityService._();

  static DeviceIntegrityPlatform? _platform;

  /// Getter platform delegate saat ini.
  @visibleForTesting
  static DeviceIntegrityPlatform get platform =>
      _platform ?? const DefaultDeviceIntegrityPlatform();

  /// Setter platform khusus pengujian unit (*mocking*).
  @visibleForTesting
  static set platform(DeviceIntegrityPlatform? value) => _platform = value;

  /// Daftar paket toko resmi Android yang diizinkan (Anti-Sideloading).
  static const Set<String> officialAndroidStores = {
    'com.android.vending', // Google Play Store
    'com.sec.android.app.samsungapps', // Samsung Galaxy Store
    'com.huawei.appmarket', // Huawei AppGallery
    'com.xiaomi.mipicks', // Xiaomi GetApps
    'com.amazon.venezia', // Amazon Appstore
  };

  /// Daftar identifier toko resmi iOS yang diizinkan.
  static const Set<String> officialIosStores = {
    'com.apple.appstore',
    'com.apple.testflight',
  };

  /// Memeriksa integritas perangkat secara menyeluruh.
  ///
  /// Mengembalikan [SecurityViolationType] jika terdeteksi pelanggaran, atau
  /// `null` jika aman.
  ///
  /// Pemeriksaan otomatis di-bypass pada mode `kDebugMode` atau
  /// environment `Dev` kecuali [enforceInDebug] bernilai `true`.
  static Future<SecurityViolationType?> checkIntegrity({
    String? expectedSignature,
    bool? enforceInDebug,
    bool failClosedOnException = false,
  }) async {
    final shouldBypass =
        !(enforceInDebug ?? false) && (kDebugMode || EnvConfig.isDev);
    if (shouldBypass) {
      return null;
    }

    try {
      // 1. Deteksi Root (Android) dan Jailbreak (iOS)
      final isJailbroken = await platform.isJailbroken();
      if (isJailbroken) {
        return SecurityViolationType.rootOrJailbreak;
      }

      // 2. Deteksi Toko Resmi & Signature pada mode Produksi
      if (EnvConfig.isProd) {
        final isOfficial = await isInstalledFromOfficialStore();
        if (!isOfficial) {
          return SecurityViolationType.unofficialStore;
        }

        final isSigValid = await isSignatureValid(
          expectedSignature: expectedSignature,
          enforceInDebug: enforceInDebug,
        );
        if (!isSigValid) {
          return SecurityViolationType.unofficialStore;
        }
      }
    } on Object catch (e, stackTrace) {
      debugPrint(
        'DeviceIntegrityService: Gagal memverifikasi integritas - $e\n'
        '$stackTrace',
      );
      if (failClosedOnException) {
        return SecurityViolationType.rootOrJailbreak;
      }
    }

    return null;
  }

  /// Memverifikasi apakah aplikasi diinstal secara resmi dari toko aplikasi
  /// terdaftar (Google Play Store, TestFlight, App Store, dll).
  static Future<bool> isInstalledFromOfficialStore() async {
    try {
      final currentPlatform = platform.targetPlatform;

      // Platform non-mobile (misal desktop/web saat testing) diizinkan
      if (currentPlatform != TargetPlatform.android &&
          currentPlatform != TargetPlatform.iOS) {
        return true;
      }

      final rawInstaller = await platform.getInstallerStore();
      if (rawInstaller == null || rawInstaller.trim().isEmpty) {
        return false;
      }

      final installer = rawInstaller.toLowerCase().trim();

      return switch (currentPlatform) {
        TargetPlatform.android => officialAndroidStores.contains(installer),
        TargetPlatform.iOS => officialIosStores.contains(installer),
        _ => true,
      };
    } on Object catch (e, stackTrace) {
      debugPrint(
        'DeviceIntegrityService: Gagal memeriksa installer store - $e\n'
        '$stackTrace',
      );
      return false;
    }
  }

  /// Memverifikasi apakah SHA-256 signature sertifikat rilis cocok dengan
  /// yang dikonfigurasi pada mode produksi.
  ///
  /// Hanya dievaluasi pada platform [TargetPlatform.android]. Pada platform
  /// lain (seperti iOS), metode ini selalu mengembalikan `true`.
  static Future<bool> isSignatureValid({
    String? expectedSignature,
    bool? enforceInDebug,
  }) async {
    final currentPlatform = platform.targetPlatform;

    // Signature APK hanya berlaku untuk Android. iOS menggunakan FairPlay DRM.
    if (currentPlatform != TargetPlatform.android) {
      return true;
    }

    final shouldBypass =
        !(enforceInDebug ?? false) && (kDebugMode || EnvConfig.isDev);
    if (shouldBypass) {
      return true;
    }

    final rawExpected = expectedSignature ?? EnvConfig.officialAppSignature;
    if (rawExpected == null || rawExpected.trim().isEmpty) {
      return true;
    }

    try {
      final currentSig = await platform.getBuildSignature();
      final cleanCurrent = _normalizeSignature(currentSig);
      if (cleanCurrent.isEmpty) {
        return false;
      }

      final expectedSet = rawExpected
          .split(',')
          .map(_normalizeSignature)
          .where((sig) => sig.isNotEmpty)
          .toSet();

      if (expectedSet.isEmpty) {
        return true;
      }

      return expectedSet.contains(cleanCurrent);
    } on Object catch (e, stackTrace) {
      debugPrint(
        'DeviceIntegrityService: Gagal memvalidasi build signature - $e\n'
        '$stackTrace',
      );
      return false;
    }
  }

  static final _signatureSeparatorRegex = RegExp(r'[:\s\-]');

  static String _normalizeSignature(String sig) {
    return sig.replaceAll(_signatureSeparatorRegex, '').toLowerCase().trim();
  }
}
