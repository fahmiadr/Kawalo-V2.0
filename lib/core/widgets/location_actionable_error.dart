/// @docImport 'package:kawalo_mobile/features/information/presentation/widgets/map_picker/app_map_picker_dialog.dart';
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/services/app_launcher_service.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_actionable_error.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';

export 'package:kawalo_mobile/core/widgets/app_actionable_error.dart'
    show AppActionableErrorData, AppActionableErrorThemeMode;

/// Adapter dan Facade terpadu untuk mentransformasikan kegagalan inspeksi
/// lokasi ([LocationResult]) menjadi konfigurasi antarmuka
/// [AppActionableErrorData].
///
/// Menyediakan representasi visual ramah pengguna lengkap dengan judul, pesan,
/// panduan pemecahan masalah (*troubleshooting tips*), serta tombol aksi nyata
/// (seperti membuka pengaturan sistem operasi atau mencoba ulang perolehan
/// sinyal GPS).
///
/// Contoh penggunaan dalam komponen UI atau dialog:
/// ```dart
/// final locationResult = await locationService.getCurrentPosition();
/// if (locationResult.isFailure) {
///   await LocationActionableError.showBottomSheet<void>(
///     context,
///     result: locationResult,
///     onRetry: () => fetchLocation(),
///   );
/// }
/// ```
abstract final class LocationActionableError {
  const LocationActionableError._();

  /// Pesan default saat deteksi sinyal GPS mengalami batas waktu (timeout).
  static const String defaultTimeoutMessage =
      'Waktu deteksi lokasi habis. Pastikan berada di area terbuka.';

  /// Label tombol aksi coba lagi untuk notifikasi batas waktu (timeout).
  static const String retryActionLabel = 'Coba lagi';

  /// Menampilkan notifikasi [AppSnackbar] saat batas waktu deteksi lokasi habis
  /// ([LocationStatus.timeout]).
  ///
  /// Mengarahkan pengguna untuk memastikan berada di area terbuka dan
  /// menyediakan tombol aksi coba lagi via [onRetry].
  static void showTimeoutSnackbar(
    BuildContext context, {
    VoidCallback? onRetry,
    String? message,
  }) {
    AppSnackbar.show(
      context,
      message: message ?? defaultTimeoutMessage,
      actionLabel: onRetry != null ? retryActionLabel : null,
      onAction: onRetry,
    );
  }

  /// Menampilkan modal lembar bawah (*modal bottom sheet*) terstandarisasi
  /// untuk merespons kegagalan inspeksi lokasi [result].
  ///
  /// Memanfaatkan [AppActionableError.showBottomSheet] untuk me-render data
  /// yang dihasilkan oleh [fromLocationResult].
  ///
  /// Callback [onDismiss] dipanggil saat aksi sekunder ditekan atau modal
  /// ditutup (default: memanggil `Navigator.of(context).maybePop()`).
  /// Callback [onRetry] dipanggil saat tombol aksi primer ditekan untuk mencoba
  /// ulang perolehan lokasi perangkat.
  ///
  /// Dependensi [launcherService], [openAppSettingsFn], dan
  /// [openLocationSettingsFn] dapat diinjeksi untuk memfasilitasi pengujian
  /// unit tanpa memicu intent sistem operasi sesungguhnya (Pure DI).
  static Future<T?> showBottomSheet<T>(
    BuildContext context, {
    required LocationResult result,
    VoidCallback? onDismiss,
    VoidCallback? onRetry,
    VoidCallback? onOpenSettings,
    Future<bool> Function()? openAppSettingsFn,
    Future<bool> Function()? openLocationSettingsFn,
    AppLauncherService launcherService = const DefaultAppLauncherService(),
    AppActionableErrorThemeMode themeMode = AppActionableErrorThemeMode.system,
    String? secondaryActionLabel,
    String? message,
  }) {
    final data = fromLocationResult(
      result,
      onDismiss: onDismiss ?? () => Navigator.of(context).maybePop(),
      onRetry: onRetry,
      onOpenSettings: onOpenSettings,
      openAppSettingsFn: openAppSettingsFn,
      openLocationSettingsFn: openLocationSettingsFn,
      launcherService: launcherService,
      themeMode: themeMode,
      secondaryActionLabel: secondaryActionLabel,
      message: message,
    );
    return AppActionableError.showBottomSheet<T>(
      context,
      data: data,
    );
  }

  /// Menghasilkan model galat saat layanan GPS atau sensor lokasi
  /// perangkat dalam keadaan nonaktif ([LocationStatus.serviceDisabled]).
  ///
  /// Menyediakan tombol aksi primer untuk membuka pengaturan lokasi sistem
  /// operasi melalui [openLocationSettingsFn] atau
  /// [AppLauncherService.openLocationSettings].
  ///
  /// Callback [onDismiss] ditugaskan ke tombol aksi sekunder
  /// ([secondaryActionLabel], default: `'Pilih manual'`).
  static AppActionableErrorData serviceDisabled({
    required VoidCallback onDismiss,
    VoidCallback? onRetry,
    VoidCallback? onOpenSettings,
    Future<bool> Function()? openLocationSettingsFn,
    AppLauncherService launcherService = const DefaultAppLauncherService(),
    AppActionableErrorThemeMode themeMode = AppActionableErrorThemeMode.system,
    String? secondaryActionLabel,
    String? message,
  }) {
    return AppActionableErrorData.actionable(
      icon: KawaloVectors.gpsDisconnectedFilled,
      title: 'Layanan lokasi belum diaktifkan',
      message: message ??
          'Layanan lokasi pada perangkat Anda sedang nonaktif. '
              'Aktifkan lokasi untuk menentukan posisi Anda di peta.',
      troubleshootingTips: const [
        'Ketuk Aktifkan lokasi di bawah.',
        'Nyalakan Layanan Lokasi di pengaturan perangkat Anda.',
        'Kembali ke aplikasi untuk melanjutkan.',
      ],
      primaryActionLabel: 'Aktifkan lokasi',
      onPrimaryAction: _launchIntent(
        overrideFn: openLocationSettingsFn,
        defaultFn: launcherService.openLocationSettings,
        onAction: onOpenSettings,
      ),
      secondaryActionLabel: secondaryActionLabel ?? 'Pilih manual',
      onSecondaryAction: onDismiss,
      themeMode: themeMode,
    );
  }

  /// Menghasilkan model galat saat izin akses lokasi ditolak sementara oleh
  /// pengguna ([LocationStatus.permissionDenied]).
  ///
  /// Menyediakan tombol aksi primer `'Izinkan akses'` jika [onRetry]
  /// disediakan.
  /// Tombol aksi sekunder ([secondaryActionLabel], default: `'Pilih manual'`)
  /// memanggil [onDismiss] untuk memfasilitasi alur pemilihan koordinat
  /// alternatif.
  static AppActionableErrorData permissionDenied({
    required VoidCallback onDismiss,
    VoidCallback? onRetry,
    String? message,
    AppActionableErrorThemeMode themeMode = AppActionableErrorThemeMode.system,
    String? secondaryActionLabel,
  }) {
    return AppActionableErrorData.actionable(
      icon: KawaloVectors.location01Filled,
      title: 'Izin akses lokasi dibutuhkan',
      message: message ??
          'Izin akses lokasi diperlukan untuk menentukan posisi Anda '
              'di peta.',
      troubleshootingTips: const [
        'Ketuk Izinkan akses di bawah.',
        'Pilih opsi "Saat aplikasi digunakan" ketika dialog sistem muncul.',
        'Atau geser peta untuk menentukan titik secara manual.',
      ],
      primaryActionLabel: onRetry != null ? 'Izinkan akses' : null,
      onPrimaryAction: onRetry,
      secondaryActionLabel: secondaryActionLabel ?? 'Pilih manual',
      onSecondaryAction: onDismiss,
      themeMode: themeMode,
    );
  }

  /// Menghasilkan model galat saat izin akses lokasi dinonaktifkan permanen
  /// oleh pengguna ([LocationStatus.permissionDeniedForever]).
  ///
  /// Menyediakan tombol aksi primer `'Buka pengaturan'` untuk meluncurkan
  /// halaman detail izin aplikasi di sistem operasi via [openAppSettingsFn]
  /// atau [AppLauncherService.openAppSettings].
  ///
  /// Tombol aksi sekunder ([secondaryActionLabel], default: `'Pilih manual'`)
  /// memicu [onDismiss].
  static AppActionableErrorData permissionDeniedForever({
    required VoidCallback onDismiss,
    VoidCallback? onRetry,
    VoidCallback? onOpenSettings,
    Future<bool> Function()? openAppSettingsFn,
    AppLauncherService launcherService = const DefaultAppLauncherService(),
    AppActionableErrorThemeMode themeMode = AppActionableErrorThemeMode.system,
    String? secondaryActionLabel,
    String? message,
  }) {
    return AppActionableErrorData.actionable(
      icon: KawaloVectors.locationOffline01Filled,
      title: 'Izin akses lokasi dinonaktifkan',
      message: message ??
          'Izin akses lokasi diperlukan untuk menentukan posisi Anda '
              'di peta.',
      troubleshootingTips: const [
        'Ketuk Buka pengaturan di bawah.',
        'Pilih menu Izin aplikasi.',
        'Aktifkan izin Lokasi.',
        'Kembali ke aplikasi untuk melanjutkan.',
      ],
      primaryActionLabel: 'Buka pengaturan',
      onPrimaryAction: _launchIntent(
        overrideFn: openAppSettingsFn,
        defaultFn: launcherService.openAppSettings,
        onAction: onOpenSettings,
      ),
      secondaryActionLabel: secondaryActionLabel ?? 'Pilih manual',
      onSecondaryAction: onDismiss,
      themeMode: themeMode,
    );
  }

  /// Menghasilkan model galat saat aplikasi hanya memperoleh izin lokasi
  /// perkiraan (approximate) padahal izin lokasi presisi mutlak diperlukan
  /// ([LocationStatus.preciseLocationRequired]).
  ///
  /// Menyediakan tombol aksi primer `'Buka pengaturan'` untuk mengarahkan
  /// pengguna mengaktifkan "Gunakan lokasi akurat" di pengaturan aplikasi via
  /// [openAppSettingsFn] atau [AppLauncherService.openAppSettings].
  ///
  /// Tombol aksi sekunder ([secondaryActionLabel], default: `'Pilih manual'`)
  /// memicu [onDismiss].
  static AppActionableErrorData preciseLocationRequired({
    required VoidCallback onDismiss,
    VoidCallback? onRetry,
    VoidCallback? onOpenSettings,
    Future<bool> Function()? openAppSettingsFn,
    AppLauncherService launcherService = const DefaultAppLauncherService(),
    AppActionableErrorThemeMode themeMode = AppActionableErrorThemeMode.system,
    String? secondaryActionLabel,
    String? message,
  }) {
    return AppActionableErrorData.actionable(
      icon: KawaloVectors.location01Filled,
      title: 'Akses lokasi presisi diperlukan',
      message: message ??
          'Aplikasi memerlukan izin lokasi presisi untuk menentukan posisi '
              'Anda di peta secara akurat. Lokasi perkiraan tidak didukung.',
      troubleshootingTips: const [
        'Ketuk Buka pengaturan di bawah.',
        'Pilih menu Izin, lalu buka Lokasi.',
        'Aktifkan Gunakan lokasi akurat.',
        'Kembali ke aplikasi untuk melanjutkan.',
      ],
      primaryActionLabel: 'Buka pengaturan',
      onPrimaryAction: _launchIntent(
        overrideFn: openAppSettingsFn,
        defaultFn: launcherService.openAppSettings,
        onAction: onOpenSettings,
      ),
      secondaryActionLabel: secondaryActionLabel ?? 'Pilih manual',
      onSecondaryAction: onDismiss,
      themeMode: themeMode,
    );
  }

  /// Menghasilkan model galat saat terdeteksi manipulasi sinyal lokasi atau
  /// aplikasi penyedia lokasi tiruan ([LocationStatus.mockLocationDetected]).
  ///
  /// Menegakkan integritas data dengan menolak koordinat palsu dan memberikan
  /// langkah mitigasi bagi pengguna untuk mematikan simulasi lokasi.
  static AppActionableErrorData mockLocationDetected({
    required VoidCallback onDismiss,
    VoidCallback? onRetry,
    AppActionableErrorThemeMode themeMode = AppActionableErrorThemeMode.system,
    String? secondaryActionLabel,
    String? message,
  }) {
    return AppActionableErrorData.actionable(
      icon: KawaloVectors.shieldOffFilled,
      title: 'Lokasi tiruan terdeteksi',
      message: message ??
          'Sistem mendeteksi penggunaan aplikasi lokasi tiruan. '
              'Demi integritas data, lokasi tiruan tidak dapat digunakan.',
      troubleshootingTips: const [
        'Tutup dan nonaktifkan aplikasi penyedia lokasi tiruan.',
        'Pastikan opsi pengembang tidak menyetel aplikasi lokasi tiruan.',
        'Ketuk Coba lagi untuk mendeteksi ulang lokasi asli.',
      ],
      primaryActionLabel: onRetry != null ? 'Coba lagi' : null,
      onPrimaryAction: onRetry,
      secondaryActionLabel: secondaryActionLabel ?? 'Kembali',
      onSecondaryAction: onDismiss,
      themeMode: themeMode,
    );
  }

  /// Menghasilkan model galat saat terjadi kesalahan platform atau galat
  /// tak terduga ([LocationStatus.unknownError]).
  ///
  /// Menampilkan pesan spesifik [message] dengan opsi mencoba ulang via
  /// [onRetry] atau menutup dialog via [onDismiss].
  static AppActionableErrorData unexpected({
    required String message,
    required VoidCallback onDismiss,
    VoidCallback? onRetry,
    AppActionableErrorThemeMode themeMode = AppActionableErrorThemeMode.system,
    String? secondaryActionLabel,
  }) {
    return AppActionableErrorData(
      icon: KawaloVectors.alertSquareFilled,
      title: 'Gagal mendeteksi lokasi',
      message: message,
      isUnexpected: true,
      troubleshootingTips: const [
        'Ketuk Coba lagi untuk mendeteksi ulang lokasi.',
        'Tutup aplikasi dari daftar aplikasi terkini, lalu buka kembali.',
      ],
      primaryActionLabel: onRetry != null ? 'Coba lagi' : 'Tutup',
      onPrimaryAction: onRetry ?? onDismiss,
      secondaryActionLabel:
          onRetry != null ? (secondaryActionLabel ?? 'Pilih manual') : null,
      onSecondaryAction: onRetry != null ? onDismiss : null,
      themeMode: themeMode,
    );
  }

  /// Memetakan instans [LocationResult] ke dalam [AppActionableErrorData]
  /// yang sesuai dengan [LocationStatus].
  ///
  /// Menerapkan pola pemetaan Dart 3 *exhaustive switch expression* untuk
  /// memastikan penanganan lengkap seluruh status kegagalan lokasi.
  ///
  /// Melempar [ArgumentError] jika status [result] bernilai
  /// [LocationStatus.success] karena status berhasil tidak merepresentasikan
  /// galat antarmuka.
  static AppActionableErrorData fromLocationResult(
    LocationResult result, {
    required VoidCallback onDismiss,
    VoidCallback? onRetry,
    VoidCallback? onOpenSettings,
    Future<bool> Function()? openAppSettingsFn,
    Future<bool> Function()? openLocationSettingsFn,
    AppLauncherService launcherService = const DefaultAppLauncherService(),
    AppActionableErrorThemeMode themeMode = AppActionableErrorThemeMode.system,
    String? secondaryActionLabel,
    String? message,
  }) {
    return switch (result.status) {
      LocationStatus.serviceDisabled => serviceDisabled(
          onDismiss: onDismiss,
          onRetry: onRetry,
          onOpenSettings: onOpenSettings,
          openLocationSettingsFn: openLocationSettingsFn,
          launcherService: launcherService,
          themeMode: themeMode,
          secondaryActionLabel: secondaryActionLabel,
          message: message,
        ),
      LocationStatus.permissionDeniedForever => permissionDeniedForever(
          onDismiss: onDismiss,
          onRetry: onRetry,
          onOpenSettings: onOpenSettings,
          openAppSettingsFn: openAppSettingsFn,
          launcherService: launcherService,
          themeMode: themeMode,
          secondaryActionLabel: secondaryActionLabel,
          message: message,
        ),
      LocationStatus.preciseLocationRequired => preciseLocationRequired(
          onDismiss: onDismiss,
          onRetry: onRetry,
          onOpenSettings: onOpenSettings,
          openAppSettingsFn: openAppSettingsFn,
          launcherService: launcherService,
          themeMode: themeMode,
          secondaryActionLabel: secondaryActionLabel,
          message: message,
        ),
      LocationStatus.permissionDenied => permissionDenied(
          onDismiss: onDismiss,
          onRetry: onRetry,
          message: message ?? result.errorMessage,
          themeMode: themeMode,
          secondaryActionLabel: secondaryActionLabel,
        ),
      LocationStatus.mockLocationDetected => mockLocationDetected(
          onDismiss: onDismiss,
          onRetry: onRetry,
          themeMode: themeMode,
          secondaryActionLabel: secondaryActionLabel,
          message: message,
        ),
      LocationStatus.timeout => throw ArgumentError.value(
          result.status,
          'result.status',
          'LocationStatus.timeout tidak menggunakan modal bottom sheet. '
              'Gunakan LocationActionableError.showTimeoutSnackbar().',
        ),
      LocationStatus.unknownError => unexpected(
          message: message ??
              result.errorMessage ??
              'Terjadi kendala saat menghubungkan sensor lokasi perangkat.',
          onDismiss: onDismiss,
          onRetry: onRetry,
          themeMode: themeMode,
          secondaryActionLabel: secondaryActionLabel,
        ),
      LocationStatus.success => throw ArgumentError.value(
          result.status,
          'result.status',
          'LocationStatus.success tidak dapat dipetakan ke actionable error.',
        ),
    };
  }

  /// Helper fungsional internal untuk meluncurkan intent pengaturan OS
  /// dengan memprioritaskan fungsi pengganti ([overrideFn]) jika tersedia.
  static VoidCallback _launchIntent({
    required Future<bool> Function()? overrideFn,
    required Future<bool> Function() defaultFn,
    VoidCallback? onAction,
  }) {
    return () {
      onAction?.call();
      unawaited((overrideFn ?? defaultFn)());
    };
  }
}
