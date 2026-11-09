import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kawalo_mobile/core/error/diagnostic_error_formatter.dart';
import 'package:kawalo_mobile/core/services/app_launcher_service.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_actionable_error.dart';

/// Helper pemetaan kesalahan terstandarisasi untuk antarmuka modul kamera.
///
/// Mengonversi berbagai bentuk galat platform, [CameraException], maupun
/// kegagalan runtime menjadi model tampilan [AppActionableErrorData] yang
/// ramah pengguna, dilengkapi tips pemecahan masalah serta tombol aksi nyata.
class CameraActionableError {
  const CameraActionableError._();

  /// Memformat rincian teknis diagnostik galat menggunakan
  /// [DiagnosticErrorFormatter] berstandar proyek.
  ///
  /// Menerapkan pola GoF Strategy dengan sanitasi token pada lingkungan
  /// produksi jika [isProduction] bernilai `true`. Parameter [domainPrefix]
  /// menentukan awalan kode diagnostik (default: `'CAM'`), dan [errorFormatter]
  /// menyediakan strategi pemformatan kustom jika diberikan.
  static String formatTechnicalDetails(
    Object error, {
    DiagnosticErrorFormatter? errorFormatter,
    bool? isProduction,
    String? domainPrefix = 'CAM',
  }) {
    return DiagnosticErrorFormatter.formatError(
      error,
      domainPrefix: domainPrefix,
      isProduction: isProduction,
      formatter: errorFormatter,
    );
  }

  /// Membangun model galat penolakan izin kamera dengan panduan ke menu
  /// pengaturan.
  static AppActionableErrorData _buildPermissionDenied({
    required VoidCallback onExit,
    Future<bool> Function()? openAppSettingsFn,
    AppLauncherService launcherService = const DefaultAppLauncherService(),
  }) {
    return AppActionableErrorData(
      icon: KawaloVectors.cameraOff01Filled,
      title: 'Izin kamera dinonaktifkan',
      message: 'Izin kamera diperlukan untuk mengambil foto.',
      troubleshootingTips: const [
        'Ketuk Buka pengaturan di bawah.',
        'Pilih menu Izin aplikasi.',
        'Aktifkan izin Kamera.',
        'Kembali ke aplikasi untuk melanjutkan.',
      ],
      primaryActionLabel: 'Buka pengaturan',
      onPrimaryAction: () {
        if (openAppSettingsFn != null) {
          unawaited(openAppSettingsFn());
        } else {
          unawaited(launcherService.openAppSettings());
        }
      },
      secondaryActionLabel: 'Kembali',
      onSecondaryAction: onExit,
      themeMode: AppActionableErrorThemeMode.dark,
    );
  }

  /// Memetakan [CameraException] atau galat platform ke dalam
  /// [AppActionableErrorData].
  ///
  /// Mengidentifikasi galat penolakan izin kamera, sensor yang sedang dikunci
  /// oleh aplikasi lain (*CameraInUse*), atau kendala inisialisasi tak terduga.
  /// Callback [onRetry] dieksekusi saat tombol coba lagi ditekan, dan [onExit]
  /// dipanggil ketika pengguna memilih kembali/menutup layar.
  /// Parameter [openAppSettingsFn] dan [launcherService] digunakan untuk
  /// mengarahkan pengguna ke pengaturan perizinan sistem operasi.
  static AppActionableErrorData fromCameraException(
    CameraException e, {
    required VoidCallback onRetry,
    required VoidCallback onExit,
    Future<bool> Function()? openAppSettingsFn,
    AppLauncherService launcherService = const DefaultAppLauncherService(),
    DiagnosticErrorFormatter? errorFormatter,
    bool? isProduction,
  }) {
    final code = e.code;
    final desc = e.description?.toLowerCase() ?? '';
    final codeLower = code.toLowerCase();
    final isPermissionDenied = code == 'CameraAccessDenied' ||
        code == 'CameraAccessDeniedWithoutPrompt' ||
        code == 'cameraPermission' ||
        code == 'permissionDenied' ||
        codeLower.contains('permission') ||
        codeLower.contains('denied') ||
        desc.contains('permission') ||
        desc.contains('denied');

    if (isPermissionDenied) {
      return _buildPermissionDenied(
        onExit: onExit,
        openAppSettingsFn: openAppSettingsFn,
        launcherService: launcherService,
      );
    }

    final isCameraInUse = code == 'CameraInUse' ||
        code == 'cameraInUse' ||
        code == 'cameraExclusiveAccessFailed';

    if (isCameraInUse) {
      return AppActionableErrorData(
        icon: KawaloVectors.alert02Filled,
        title: 'Kamera sedang digunakan',
        message: 'Sensor kamera sedang diakses atau dikunci oleh '
            'aplikasi lain di perangkat Anda.',
        troubleshootingTips: const [
          'Tutup panggilan video atau aplikasi kamera lain yang sedang aktif.',
          'Pastikan tidak ada perekaman latar belakang yang aktif.',
          'Ketuk Coba lagi untuk menghubungkan ulang kamera.',
        ],
        primaryActionLabel: 'Coba lagi',
        onPrimaryAction: onRetry,
        secondaryActionLabel: 'Kembali',
        onSecondaryAction: onExit,
        themeMode: AppActionableErrorThemeMode.dark,
      );
    }

    // Kesalahan Tak Terduga (Unexpected)
    return AppActionableErrorData(
      icon: KawaloVectors.alertDiamondFilled,
      title: 'Kendala inisialisasi kamera',
      message: 'Modul kamera mengalami kendala saat dihubungkan ke sistem.',
      technicalDetails: formatTechnicalDetails(
        e,
        errorFormatter: errorFormatter,
        isProduction: isProduction,
      ),
      isUnexpected: true,
      troubleshootingTips: const [
        'Ketuk Coba lagi untuk memuat ulang kamera.',
        'Tutup aplikasi dari daftar aplikasi terkini, lalu buka kembali.',
      ],
      primaryActionLabel: 'Coba lagi',
      onPrimaryAction: onRetry,
      secondaryActionLabel: 'Kembali',
      onSecondaryAction: onExit,
      themeMode: AppActionableErrorThemeMode.dark,
    );
  }

  /// Memetakan kesalahan inisialisasi kamera umum ke dalam
  /// [AppActionableErrorData].
  ///
  /// Jika [error] merupakan instans [CameraException], penanganan didelegasikan
  /// ke [fromCameraException]. Jika berupa galat platform lain yang mengandung
  /// indikasi penolakan izin, antarmuka akan menampilkan panduan membuka
  /// pengaturan OS. Kesalahan lainnya akan dipetakan sebagai galat tak
  /// terduga via [unexpected].
  static AppActionableErrorData fromInitializationError(
    Object error, {
    required VoidCallback onRetry,
    required VoidCallback onExit,
    Future<bool> Function()? openAppSettingsFn,
    AppLauncherService launcherService = const DefaultAppLauncherService(),
    DiagnosticErrorFormatter? errorFormatter,
    bool? isProduction,
  }) {
    if (error is CameraException) {
      return fromCameraException(
        error,
        onRetry: onRetry,
        onExit: onExit,
        openAppSettingsFn: openAppSettingsFn,
        launcherService: launcherService,
        errorFormatter: errorFormatter,
        isProduction: isProduction,
      );
    }

    final errorStr = error.toString().toLowerCase();
    final isPermissionDenied = errorStr.contains('permission') ||
        errorStr.contains('denied') ||
        errorStr.contains('cameraaccessdenied');

    if (isPermissionDenied) {
      return _buildPermissionDenied(
        onExit: onExit,
        openAppSettingsFn: openAppSettingsFn,
        launcherService: launcherService,
      );
    }

    return unexpected(
      error,
      onRetry: onRetry,
      onExit: onExit,
      errorFormatter: errorFormatter,
      isProduction: isProduction,
    );
  }

  /// Membuat [AppActionableErrorData] ketika perangkat tidak memiliki sensor
  /// kamera aktif.
  ///
  /// Menampilkan pesan informatif bahwa sensor kamera fisik tidak terdeteksi
  /// beserta langkah-langkah diagnostik perangkat keras.
  static AppActionableErrorData noCamerasAvailable({
    required VoidCallback onRetry,
    required VoidCallback onExit,
  }) {
    return AppActionableErrorData(
      icon: KawaloVectors.cameraOff01,
      title: 'Kamera tidak terdeteksi',
      message: 'Sistem tidak menemukan modul kamera aktif pada perangkat ini.',
      troubleshootingTips: const [
        'Pastikan perangkat memiliki modul kamera fisik yang berfungsi.',
        'Periksa apakah kebijakan keamanan membatasi akses kamera.',
        'Ketuk Coba lagi setelah memastikan kamera tersedia.',
      ],
      primaryActionLabel: 'Coba lagi',
      onPrimaryAction: onRetry,
      secondaryActionLabel: 'Kembali',
      onSecondaryAction: onExit,
      themeMode: AppActionableErrorThemeMode.dark,
    );
  }

  /// Membuat [AppActionableErrorData] untuk kesalahan teknis generic yang
  /// tak terduga.
  ///
  /// Menyertakan rincian teknis yang telah diformat menggunakan
  /// [formatTechnicalDetails] serta panduan pemecahan masalah dasar.
  static AppActionableErrorData unexpected(
    Object error, {
    required VoidCallback onRetry,
    required VoidCallback onExit,
    DiagnosticErrorFormatter? errorFormatter,
    bool? isProduction,
  }) {
    return AppActionableErrorData(
      icon: KawaloVectors.alertSquareFilled,
      title: 'Terjadi kesalahan teknis',
      message: 'Sistem mendeteksi kendala tak terduga pada antarmuka kamera.',
      technicalDetails: formatTechnicalDetails(
        error,
        errorFormatter: errorFormatter,
        isProduction: isProduction,
      ),
      isUnexpected: true,
      troubleshootingTips: const [
        'Ketuk Coba lagi untuk memuat ulang kamera.',
        'Tutup aplikasi dari daftar aplikasi terkini, lalu buka kembali.',
        'Mulai ulang perangkat jika kendala masih berlanjut.',
      ],
      primaryActionLabel: 'Coba lagi',
      onPrimaryAction: onRetry,
      secondaryActionLabel: 'Kembali',
      onSecondaryAction: onExit,
      themeMode: AppActionableErrorThemeMode.dark,
    );
  }

  /// Membuat [AppActionableErrorData] untuk kegagalan pemrosesan atau
  /// penyimpanan berkas foto.
  ///
  /// Digunakan ketika penangkapan gambar, pemotongan rasio, atau penyimpanan
  /// lokal mengalami kendala (misalnya memori internal penuh). Callback
  /// [onDismiss] dipanggil saat pengguna menutup lembar galat (*error bottom
  /// sheet*).
  static AppActionableErrorData captureFailure(
    Object error, {
    VoidCallback? onDismiss,
    DiagnosticErrorFormatter? errorFormatter,
    bool? isProduction,
  }) {
    return AppActionableErrorData(
      icon: KawaloVectors.alertCircleFilled,
      title: 'Gagal menyimpan foto',
      message: 'Terjadi kendala saat memproses atau menyimpan berkas foto. '
          'Foto sebelumnya tetap aman.',
      technicalDetails: formatTechnicalDetails(
        error,
        errorFormatter: errorFormatter,
        isProduction: isProduction,
      ),
      isUnexpected: true,
      troubleshootingTips: const [
        'Pastikan ruang penyimpanan perangkat masih mencukupi.',
        'Coba ambil foto kembali.',
      ],
      primaryActionLabel: 'Mengerti',
      onPrimaryAction: onDismiss,
    );
  }
}
