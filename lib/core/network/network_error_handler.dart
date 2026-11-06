import 'dart:io';

import 'package:dio/dio.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';

/// Handler terpusat untuk memetakan kesalahan jaringan ([DioException])
/// ke [AppException] dan konversi [Exception] ke [Failure].
///
/// Seluruh pesan kegagalan menggunakan prinsip UX Writing Material 3:
/// - Bahasa Indonesia ramah pengguna (bebas istilah teknis seperti errno).
/// - Format kalimat *sentence case*.
/// - Pesan yang solutif dan mengarahkan pengguna pada tindakan nyata.
abstract final class NetworkErrorHandler {
  const NetworkErrorHandler._();

  /// Memetakan [DioException] ke turunan [AppException] yang tepat.
  static AppException handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return const TimeoutException(
          'Waktu koneksi habis. Silakan coba beberapa saat lagi.',
          type: TimeoutType.connect,
        );

      case DioExceptionType.sendTimeout:
        return const TimeoutException(
          'Gagal mengirim data. Periksa koneksi Anda dan coba lagi.',
          type: TimeoutType.send,
        );

      case DioExceptionType.receiveTimeout:
        return const TimeoutException(
          'Layanan membutuhkan waktu terlalu lama untuk merespons. '
          'Silakan coba beberapa saat lagi.',
          type: TimeoutType.receive,
        );

      case DioExceptionType.transformTimeout:
        return const TimeoutException(
          'Layanan membutuhkan waktu terlalu lama untuk memproses data.',
          type: TimeoutType.receive,
        );

      case DioExceptionType.badCertificate:
        return const SecurityException();

      case DioExceptionType.cancel:
        return const RequestCancelledException();

      case DioExceptionType.connectionError:
        return _handleConnectionError(error);

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.unknown:
        return _handleUnknownError(error);
    }
  }

  /// Menangani error koneksi fisik / soket.
  static AppException _handleConnectionError(DioException error) {
    final rawError = error.error;
    final rawString =
        (rawError ?? error.message ?? '').toString().toLowerCase();

    // 1. Deteksi koneksi ditolak / port server mati / host unreachable / timeout
    if (rawString.contains('refused') ||
        rawString.contains('111') ||
        rawString.contains('10061') ||
        rawString.contains('econnrefused') ||
        rawString.contains('reset') ||
        rawString.contains('no route') ||
        rawString.contains('semaphore timeout') ||
        rawString.contains('host is down') ||
        rawString.contains('timed out') ||
        rawString.contains('timeout')) {
      return const ConnectionRefusedException();
    }

    // 2. Deteksi ketiadaan internet murni (rute jaringan mati / DNS total)
    if (rawString.contains('failed host lookup') ||
        rawString.contains('network is unreachable') ||
        rawString.contains('no address associated')) {
      return const NoInternetException();
    }

    // 3. Fallback: SocketException lainnya saat menghubungi endpoint server
    if (rawError is SocketException) {
      return const ConnectionRefusedException();
    }

    return const ConnectionRefusedException();
  }

  /// Menangani error respons HTTP (4xx / 5xx).
  static AppException _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    String? serverMessage;
    String? errorCode;
    dynamic details;

    if (responseData is Map<String, dynamic>) {
      serverMessage = responseData['message']?.toString();
      errorCode = responseData['error_code']?.toString();
      details = responseData['details'];
    }

    // Jika pesan dari backend adalah error database / server internal,
    // ganti dengan pesan ramah pengguna agar arsitektur tidak terekspos.
    if (errorCode == 'DATABASE_ERROR' ||
        errorCode == 'INTERNAL_SERVER_ERROR' ||
        (serverMessage != null && _isTechnicalMessage(serverMessage))) {
      serverMessage =
          'Terjadi kendala pada sistem. Silakan coba beberapa saat lagi.';
    }

    final message = serverMessage ?? _defaultMessageForStatus(statusCode);

    if (statusCode == 401) {
      return AuthException(message, statusCode);
    }

    return ServerException(message, statusCode, errorCode, details);
  }

  /// Menangani error bertipe unknown.
  static AppException _handleUnknownError(DioException error) {
    final rawError = error.error;
    if (rawError is SocketException) {
      final rawString =
          (rawError.osError?.message ?? rawError.message).toLowerCase();
      if (rawString.contains('network is unreachable') ||
          rawString.contains('no address associated')) {
        return const NoInternetException();
      }
      return const ConnectionRefusedException();
    }
    return const NetworkException(
      'Terjadi kendala pada koneksi. Silakan coba beberapa saat lagi.',
    );
  }

  /// Menghasilkan pesan fallback ramah pengguna sesuai kode status HTTP.
  static String _defaultMessageForStatus(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Permintaan tidak valid. Periksa kembali data Anda.';
      case 401:
        return 'Sesi Anda telah berakhir. Silakan masuk kembali.';
      case 403:
        return 'Anda tidak memiliki akses ke layanan ini.';
      case 404:
        return 'Data atau layanan tidak ditemukan.';
      case 408:
        return 'Waktu permintaan habis. Silakan coba lagi.';
      case 409:
        return 'Terjadi konflik data. Silakan coba lagi.';
      case 422:
        return 'Data yang dikirim tidak dapat diproses.';
      case 429:
        return 'Terlalu banyak permintaan. '
            'Mohon tunggu beberapa saat sebelum mencoba kembali.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Terjadi kendala pada sistem. Silakan coba beberapa saat lagi.';
      default:
        return 'Terjadi kesalahan pada layanan '
            '(${statusCode ?? 'tidak diketahui'}).';
    }
  }

  /// Memeriksa apakah pesan mengandung istilah teknis yang tidak
  /// ramah pengguna.
  static bool _isTechnicalMessage(String message) {
    final lower = message.toLowerCase();
    return lower.contains('syntax error') ||
        lower.contains('prisma') ||
        lower.contains('sql') ||
        lower.contains('database') ||
        lower.contains('connection refused') ||
        lower.contains('query failed');
  }

  /// Mengonversi [Exception] ke [Failure] untuk lapisan Repository.
  static Failure handleExceptionToFailure(Object exception) {
    if (exception is NoInternetException) {
      return NoInternetFailure(exception.message);
    }
    if (exception is ConnectionRefusedException) {
      return ConnectionRefusedFailure(exception.message);
    }
    if (exception is TimeoutException) {
      return TimeoutFailure(exception.message);
    }
    if (exception is SecurityException) {
      return SecurityFailure(exception.message);
    }
    if (exception is AuthException) {
      return AuthFailure(exception.message, exception.statusCode);
    }
    if (exception is ServerException) {
      return ServerFailure(
        exception.message,
        exception.statusCode,
        exception.errorCode,
      );
    }
    if (exception is NetworkException) {
      return NetworkFailure(exception.message, exception.statusCode);
    }
    if (exception is CacheException) {
      return CacheFailure(exception.message);
    }
    if (exception is RequestCancelledException) {
      return RequestCancelledFailure(exception.message);
    }
    return ServerFailure(exception.toString());
  }
}
