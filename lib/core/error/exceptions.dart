/// Kelas dasar untuk seluruh Exception di aplikasi Kawalo.
abstract class AppException implements Exception {
  const AppException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;

  @override
  String toString() => '$runtimeType: $message (statusCode: $statusCode)';
}

/// Exception untuk error dari server (HTTP status code 4xx / 5xx).
class ServerException extends AppException {
  const ServerException([
    super.message = 'Terjadi kesalahan pada server.',
    super.statusCode,
    this.errorCode,
    this.details,
  ]);

  final String? errorCode;
  final dynamic details;

  @override
  String toString() =>
      'ServerException: $message (statusCode: $statusCode, '
      'errorCode: $errorCode)';
}

/// Exception umum untuk kegagalan jaringan atau koneksi dari sisi klien.
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Tidak dapat terhubung ke jaringan.',
    super.statusCode,
  ]);
}

/// Exception saat perangkat tidak memiliki koneksi internet aktif
/// atau DNS gagal.
class NoInternetException extends NetworkException {
  const NoInternetException([
    super.message =
        'Tidak ada koneksi internet. Periksa koneksi data atau Wi-Fi Anda.',
  ]);
}

/// Exception saat server menolak koneksi (port tertutup, host tidak dapat
/// dihubungi).
class ConnectionRefusedException extends NetworkException {
  const ConnectionRefusedException([
    super.message =
        'Tidak dapat terhubung ke layanan. Silakan coba beberapa saat lagi.',
  ]);
}

/// Jenis batas waktu permintaan jaringan.
enum TimeoutType { connect, send, receive }

/// Exception saat terjadi batas waktu (timeout) pada koneksi, pengiriman,
/// atau penerimaan.
class TimeoutException extends NetworkException {
  const TimeoutException(super.message, {this.type});

  final TimeoutType? type;

  @override
  String toString() => 'TimeoutException: $message (type: $type)';
}

/// Exception untuk masalah keamanan TLS/SSL (misalnya bad certificate).
class SecurityException extends NetworkException {
  const SecurityException([
    super.message = 'Koneksi tidak aman. Silakan coba lagi nanti.',
  ]);
}

/// Exception khusus untuk masalah autentikasi atau sesi.
class AuthException extends AppException {
  const AuthException([
    super.message = 'Sesi Anda telah berakhir. Silakan masuk kembali.',
    super.statusCode = 401,
  ]);
}

/// Exception untuk kegagalan penyimpanan lokal / cache.
class CacheException extends AppException {
  const CacheException([super.message = 'Gagal memproses data lokal.']);
}

/// Exception saat permintaan jaringan dibatalkan secara eksplisit oleh klien
/// (misal karena request baru menggantikan pencarian lama via CancelToken).
class RequestCancelledException extends AppException {
  const RequestCancelledException([super.message = 'Permintaan dibatalkan.']);
}

/// Exception yang dilempar ketika konfigurasi lingkungan melanggar
/// aturan keamanan (security guardrails).
class ConfigurationSecurityException implements Exception {
  const ConfigurationSecurityException(this.message);
  final String message;

  @override
  String toString() => 'ConfigurationSecurityException: $message';
}
