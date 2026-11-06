/// @docImport 'package:kawalo_mobile/core/widgets/app_multi_shot_camera_screen.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:screen_brightness/screen_brightness.dart';

/// Kontrak layanan manajemen kecerahan layar perangkat untuk fitur
/// pencahayaan antarmuka (seperti *screen flash* pada
/// [AppMultiShotCameraScreen]).
///
/// Memungkinkan pembalikan ketergantungan (DIP / IoC) serta pengujian unit
/// terisolasi melalui injeksi dependensi murni (*Pure Dependency Injection*).
@immutable
abstract interface class ScreenBrightnessService {
  /// Tingkat kecerahan layar aplikasi saat ini (dalam rentang 0.0 hingga 1.0).
  ///
  /// Mengembalikan nilai default `1.0` apabila terjadi kegagalan pembacaan
  /// dari antarmuka platform native.
  Future<double> get currentBrightness;

  /// Mengatur tingkat kecerahan layar aplikasi ke nilai [brightness] tertentu
  /// (dalam rentang 0.0 hingga 1.0).
  ///
  /// Nilai [brightness] akan dibatasi secara otomatis (*clamped*) ke rentang
  /// valid 0.0 sampai 1.0. Jika nilai bernilai `NaN` atau `infinite`, operasi
  /// akan diabaikan secara aman dan mengembalikan `false`.
  ///
  /// Mengembalikan `true` jika kecerahan berhasil diubah oleh platform native,
  /// atau `false` jika terjadi kegagalan platform.
  Future<bool> setBrightness(double brightness);

  /// Mengembalikan kecerahan layar aplikasi ke tingkat default sistem operasi.
  ///
  /// Mengembalikan `true` jika kecerahan berhasil direset, atau `false` jika
  /// terjadi kegagalan platform.
  Future<bool> resetBrightness();
}

/// Implementasi bawaan [ScreenBrightnessService] berbasis pustaka
/// [ScreenBrightness].
///
/// Menyediakan perlindungan terhadap kegagalan platform native dengan menangani
/// seluruh galat secara aman (*fail-safe*) tanpa melempar unhandled exception
/// ke lapisan UI.
///
/// ### Contoh Implementasi Pure DI pada Konsumen
///
/// ```dart
/// class MyWidget extends StatefulWidget {
///   const MyWidget({
///     super.key,
///     this.brightnessService = const DefaultScreenBrightnessService(),
///   });
///
///   final ScreenBrightnessService brightnessService;
///
///   @override
///   State<MyWidget> createState() => _MyWidgetState();
/// }
/// ```
@immutable
final class DefaultScreenBrightnessService implements ScreenBrightnessService {
  /// Membuat instance [DefaultScreenBrightnessService.new].
  ///
  /// Parameter opsional [plugin] dapat disuntikkan secara eksplisit pada saat
  /// pengujian unit terisolasi (*Pure Dependency Injection*).
  const DefaultScreenBrightnessService({
    ScreenBrightness? plugin,
  }) : _plugin = plugin;

  final ScreenBrightness? _plugin;

  ScreenBrightness get _effectivePlugin => _plugin ?? ScreenBrightness();

  Future<bool> _safeAction(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<double> get currentBrightness async {
    try {
      return await _effectivePlugin.application;
    } on Object {
      return 1.0;
    }
  }

  @override
  Future<bool> setBrightness(double brightness) async {
    if (brightness.isNaN || brightness.isInfinite) return false;
    final clamped = brightness.clamp(0.0, 1.0);
    return await _safeAction(
      () => _effectivePlugin.setApplicationScreenBrightness(clamped),
    );
  }

  @override
  Future<bool> resetBrightness() =>
      _safeAction(_effectivePlugin.resetApplicationScreenBrightness);
}
