import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure(this.message, {this.statusCode, this.errorCode});
  final String message;
  final int? statusCode;
  final String? errorCode;

  @override
  List<Object?> get props => [message, statusCode, errorCode];
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Terjadi kesalahan pada server.',
    int? statusCode,
    String? errorCode,
  ]) : super(statusCode: statusCode, errorCode: errorCode);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Tidak dapat terhubung ke jaringan.',
    int? statusCode,
  ]) : super(statusCode: statusCode);
}

class NoInternetFailure extends NetworkFailure {
  const NoInternetFailure([
    super.message =
        'Tidak ada koneksi internet. Periksa koneksi data atau Wi-Fi Anda.',
  ]);

  /// Kegagalan ketika perangkat sedang offline dan penyimpanan data lokal
  /// tidak tersedia.
  const NoInternetFailure.offlineNoStorage([
    super.message = offlineNoStorageMessage,
  ]);

  /// Pesan default ketika perangkat sedang offline dan penyimpanan data
  /// lokal tidak tersedia.
  static const String offlineNoStorageMessage =
      'Perangkat sedang offline dan penyimpanan data tidak tersedia.';
}

class ConnectionRefusedFailure extends NetworkFailure {
  const ConnectionRefusedFailure([
    super.message =
        'Tidak dapat terhubung ke layanan. Silakan coba beberapa saat lagi.',
  ]);
}

class TimeoutFailure extends NetworkFailure {
  const TimeoutFailure([
    super.message = 'Waktu koneksi habis. Silakan coba beberapa saat lagi.',
  ]);
}

class SecurityFailure extends NetworkFailure {
  const SecurityFailure([
    super.message = 'Koneksi tidak aman. Silakan coba lagi nanti.',
  ]);
}

class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Sesi Anda telah berakhir. Silakan masuk kembali.',
    int? statusCode = 401,
    String? errorCode,
  ]) : super(statusCode: statusCode, errorCode: errorCode);
}

/// Failure saat pengguna tidak berhak menjalankan sebuah aksi bisnis
/// (otorisasi berbasis sesi / peran ditolak).
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([
    super.message = 'Anda tidak memiliki izin untuk melakukan aksi ini.',
    int? statusCode = 403,
    String? errorCode,
  ]) : super(statusCode: statusCode, errorCode: errorCode);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Gagal memproses data lokal.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.errorCode});
}

/// Failure saat permintaan dibatalkan secara eksplisit oleh klien via
/// CancelToken.
class RequestCancelledFailure extends Failure {
  const RequestCancelledFailure([
    super.message = 'Permintaan dibatalkan.',
  ]);
}
