/// @docImport 'package:kawalo_mobile/core/widgets/app_actionable_error.dart';
library;

import 'dart:async' as async;
import 'dart:io' show FileSystemException;

import 'package:camera/camera.dart' show CameraException;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:kawalo_mobile/core/config/env_config.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/utils/app_sanitizer.dart';

/// Kontrak GoF Strategy untuk pemformatan detail teknis diagnostik galat
/// di seluruh aplikasi Kawalo Mobile.
///
/// Digunakan oleh komponen antarmuka (seperti [AppActionableErrorView] dan
/// [AppActionableErrorData]) untuk menyajikan detail teknis pada panel
/// accordion lipat secara aman:
/// - Pada lingkungan Development & Staging, menyajikan representasi mentah
///   lengkap ([Object.toString] atau rincian internal native) untuk mempermudah
///   penelusuran masalah (*debugging*).
/// - Pada lingkungan Production, menyaring (*sanitize*) informasi sensitif
///   (path sistem berkas, stack trace, alamat memori) menjadi token diagnostik
///   ringkas berstandar proyek untuk mencegah kebocoran informasi sensitif
///   (OWASP M8).
///
/// ### Contoh Implementasi Pure DI pada Konsumen
///
/// ```dart
/// class AttendanceService {
///   const AttendanceService({
///     this.errorFormatter = const DefaultDiagnosticErrorFormatter(),
///   });
///
///   final DiagnosticErrorFormatter errorFormatter;
/// }
/// ```
@immutable
abstract interface class DiagnosticErrorFormatter {
  /// Memformat [error] secara terpusat sesuai konfigurasi lingkungan aktif.
  ///
  /// Metode fasad statis ini menyediakan akses langsung yang ramah pengembang
  /// (*batteries-included*) untuk seluruh fitur aplikasi tanpa memerlukan
  /// instansiasi manual:
  ///
  /// ```dart
  /// // Penggunaan pada fitur Absensi / GPS:
  /// final details = DiagnosticErrorFormatter.formatError(
  ///   error,
  ///   domainPrefix: 'ATT',
  /// );
  /// ```
  ///
  /// Parameter opsional [domainPrefix] menentukan prefiks domain pelapor saat
  /// terjadi galat tak terduga (default bernilai `'ERR'`). Parameter
  /// [isProduction] atau [formatter] dapat disuntikkan secara eksplisit
  /// pada saat pengujian unit terisolasi (*Pure Dependency Injection*).
  static String formatError(
    Object error, {
    String? domainPrefix,
    bool? isProduction,
    DiagnosticErrorFormatter? formatter,
  }) =>
      (formatter ??
              (isProduction == null
                  ? const DefaultDiagnosticErrorFormatter()
                  : DefaultDiagnosticErrorFormatter(
                      isProduction: isProduction,
                    )))
          .format(error, domainPrefix: domainPrefix);

  /// Memformat [error] menjadi representasi string diagnostik yang sesuai
  /// dengan kebijakan lingkungan aktif.
  ///
  /// Jika [domainPrefix] disediakan, nilai tersebut dinormalisasi menjadi
  /// huruf besar untuk mengidentifikasi modul pelapor (misalnya `'CAM'`
  /// atau `'ATT'`).
  String format(Object error, {String? domainPrefix});
}

/// Strategi pemformatan lingkungan Development & Staging.
///
/// Menyajikan string mentah lengkap ([Object.toString] atau rincian internal
/// native) tanpa penyaringan untuk mempermudah proses *debugging* oleh
/// developer dan QA.
@immutable
final class DevDiagnosticErrorFormatter implements DiagnosticErrorFormatter {
  /// Membuat instance [DevDiagnosticErrorFormatter.new].
  const DevDiagnosticErrorFormatter();

  @override
  String format(Object error, {String? domainPrefix}) => switch (error) {
    CameraException(:final code, :final description) =>
      'CameraException(code: $code, description: ${description ?? "-"})',
    _ => error.toString(),
  };
}

/// Strategi pemformatan lingkungan Production.
///
/// Menyaring (*sanitize*) informasi sensitif (path sistem berkas, stack trace,
/// alamat memori) menjadi token diagnostik aman berstandar proyek:
/// `Kode: [DOMAIN]_[REASON] [: [OS_CODE]] [(DETAIL_AMAN)]`.
@immutable
final class ProductionDiagnosticErrorFormatter
    implements DiagnosticErrorFormatter {
  /// Membuat instance [ProductionDiagnosticErrorFormatter.new].
  const ProductionDiagnosticErrorFormatter();

  static const String _cameraPrefix = 'CAMERA_';

  // Regex untuk menormalkan Type name (hanya huruf, angka, underscore).
  static final RegExp _nonAlphanumericRegex = RegExp('[^a-zA-Z0-9_]');

  // Regex untuk mendeteksi batas camelCase ke SNAKE_CASE.
  static final RegExp _camelCaseBoundaryRegex = RegExp('([a-z0-9])([A-Z])');

  // Regex untuk mengganti separator (spasi, strip, titik, slash, colon)
  // menjadi underscore.
  static final RegExp _separatorRegex = RegExp(r'[\s\-_.:/]+');

  // Menyusun string token berstandar proyek dengan pembersihan path otomatis.
  static String _renderToken(String code, {int? numericCode, String? detail}) {
    final numPart = numericCode != null ? ' [$numericCode]' : '';
    final cleanDetail = AppSanitizer.stripFilePaths(detail).trim();
    final detailPart = cleanDetail.isNotEmpty ? ' ($cleanDetail)' : '';
    return 'Kode: $code$numPart$detailPart';
  }

  // Memformat ServerException menjadi token SRV terstandarisasi.
  static String _renderServerToken(ServerException error) {
    final srvCode = AppSanitizer.cleanString(error.errorCode);
    final codeSuffix = srvCode != null
        ? '_${_normalizeGeneralCode(srvCode)}'
        : '';
    return _renderToken('SRV$codeSuffix', numericCode: error.statusCode);
  }

  @override
  String format(Object error, {String? domainPrefix}) {
    final cleanPrefix = AppSanitizer.cleanString(domainPrefix);
    final prefix = cleanPrefix != null
        ? _normalizeGeneralCode(cleanPrefix)
        : 'ERR';

    return switch (error) {
      // 1. Galat Modul Kamera Resmi
      CameraException(:final code) => _renderToken(
        'CAM_${_normalizeCameraCode(code)}',
      ),

      // 2. Galat I/O Penyimpanan Berkas & Direktori (Zero Path Leakage)
      FileSystemException(:final osError, :final message) => _renderToken(
        'STORAGE_IO_ERROR',
        numericCode: osError?.errorCode,
        detail: osError?.message ?? message,
      ),

      // 3. Galat Method Channel Platform Native OS
      PlatformException(:final code, :final message) => _renderToken(
        'PLATFORM_${_normalizeGeneralCode(code)}',
        detail: message,
      ),

      // 4. Galat Keamanan Sertifikat TLS/SSL & Konfigurasi
      SecurityException() => _renderToken('SEC_TLS_ERROR'),
      ConfigurationSecurityException() => _renderToken('SEC_CONFIG_ERROR'),

      // 5. Galat Jaringan & Waktu Habis (Timeout Kawalo & dart:async)
      TimeoutException() ||
      async.TimeoutException() => _renderToken('NET_TIMEOUT'),

      // 6. Galat Bisnis Internal Aplikasi Kawalo (AppException)
      AuthException(:final statusCode) => _renderToken(
        'AUTH_SESSION_EXPIRED',
        numericCode: statusCode,
      ),
      CacheException() => _renderToken('STORAGE_CACHE_ERROR'),
      RequestCancelledException() => _renderToken('NET_CANCELLED'),
      ServerException() => _renderServerToken(error),
      NoInternetException() => _renderToken('NET_NO_INTERNET'),
      ConnectionRefusedException() => _renderToken('NET_CONN_REFUSED'),
      NetworkException(:final statusCode) => _renderToken(
        'NET_ERROR',
        numericCode: statusCode,
      ),

      // 7. Galat Umum / Tak Terduga (Fallback Aman)
      _ => _renderToken(
        '${prefix}_UNEXPECTED',
        detail: _normalizeTypeName(error.runtimeType),
      ),
    };
  }

  // Menormalkan kode CameraException camelCase menjadi UPPERCASE_UNDERSCORE
  // serta menghapus redundansi prefix CAMERA_.
  static String _normalizeCameraCode(String code) {
    final normalized = _normalizeGeneralCode(code);
    if (normalized.startsWith(_cameraPrefix)) {
      return normalized.substring(_cameraPrefix.length);
    }
    return normalized;
  }

  // Menormalkan kode platform umum ke format UPPERCASE_UNDERSCORE.
  static String _normalizeGeneralCode(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return 'UNKNOWN';
    return trimmed
        .replaceAllMapped(
          _camelCaseBoundaryRegex,
          (match) => '${match.group(1)}_${match.group(2)}',
        )
        .replaceAll(_separatorRegex, '_')
        .toUpperCase();
  }

  // Menormalkan Type name (e.g. StateError -> StateError).
  static String _normalizeTypeName(Type type) =>
      type.toString().replaceAll(_nonAlphanumericRegex, '');
}

/// Implementasi default [DiagnosticErrorFormatter] berbasis resolusi otomatis.
///
/// Secara otomatis menentukan strategi formatter berdasarkan lingkungan aktif
/// ([isProductionEnvironment]), dengan dukungan *Pure Dependency Injection*
/// untuk keperluan pengujian terisolasi:
///
/// ```dart
/// // Resolusi otomatis berdasarkan runtime environment:
/// const formatter = DefaultDiagnosticErrorFormatter();
///
/// // Simulasi eksplisit untuk pengujian unit terisolasi:
/// const testProdFormatter = DefaultDiagnosticErrorFormatter(
///   isProduction: true,
/// );
/// ```
@immutable
final class DefaultDiagnosticErrorFormatter
    implements DiagnosticErrorFormatter {
  /// Membuat instance [DefaultDiagnosticErrorFormatter.new].
  ///
  /// Argumen [isProduction] dapat disuntikkan secara eksplisit pada saat
  /// pengujian unit tanpa memodifikasi konfigurasi lingkungan global
  /// (*Pure DI*).
  const DefaultDiagnosticErrorFormatter({this.isProduction});

  /// Apakah strategi lingkungan produksi dipaksakan secara eksplisit.
  ///
  /// Bernilai `null` jika strategi harus ditentukan secara otomatis melalui
  /// [isProductionEnvironment].
  final bool? isProduction;

  /// Apakah aplikasi saat ini sedang berjalan pada lingkungan produksi.
  ///
  /// Mengembalikan `true` apabila aplikasi berjalan pada mode rilis resmi
  /// ([kReleaseMode]) atau konfigurasi lingkungan aktif terdefinisi sebagai
  /// target produksi ([EnvConfig.isProd]).
  static bool get isProductionEnvironment =>
      kReleaseMode || (EnvConfig.isInitialized && EnvConfig.environment.isProd);

  @override
  String format(Object error, {String? domainPrefix}) =>
      ((isProduction ?? isProductionEnvironment)
              ? const ProductionDiagnosticErrorFormatter()
              : const DevDiagnosticErrorFormatter())
          .format(error, domainPrefix: domainPrefix);
}
