import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';

void main() {
  group('NetworkErrorHandler Tests', () {
    final dummyRequestOptions = RequestOptions(path: '/api/v1/test');

    test(
      'memetakan connectionTimeout ke TimeoutException & TimeoutFailure',
      () {
        final dioError = DioException(
          requestOptions: dummyRequestOptions,
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timed out',
        );

        final exception = NetworkErrorHandler.handleDioError(dioError);
        expect(exception, isA<TimeoutException>());
        expect((exception as TimeoutException).type, TimeoutType.connect);
        expect(
          exception.message,
          'Waktu koneksi habis. Silakan coba beberapa saat lagi.',
        );

        final failure = NetworkErrorHandler.handleExceptionToFailure(exception);
        expect(failure, isA<TimeoutFailure>());
        expect(
          failure.message,
          'Waktu koneksi habis. Silakan coba beberapa saat lagi.',
        );
      },
    );

    test(
      'memetakan sendTimeout ke TimeoutException & TimeoutFailure',
      () {
        final dioError = DioException(
          requestOptions: dummyRequestOptions,
          type: DioExceptionType.sendTimeout,
          message: 'Send timed out',
        );

        final exception = NetworkErrorHandler.handleDioError(dioError);
        expect(exception, isA<TimeoutException>());
        expect((exception as TimeoutException).type, TimeoutType.send);
        expect(
          exception.message,
          'Gagal mengirim data. Periksa koneksi Anda dan coba lagi.',
        );

        final failure = NetworkErrorHandler.handleExceptionToFailure(exception);
        expect(failure, isA<TimeoutFailure>());
      },
    );

    test(
      'memetakan receiveTimeout ke TimeoutException & TimeoutFailure',
      () {
        final dioError = DioException(
          requestOptions: dummyRequestOptions,
          type: DioExceptionType.receiveTimeout,
          message: 'Receive timed out',
        );

        final exception = NetworkErrorHandler.handleDioError(dioError);
        expect(exception, isA<TimeoutException>());
        expect((exception as TimeoutException).type, TimeoutType.receive);
        expect(
          exception.message,
          'Layanan membutuhkan waktu terlalu lama untuk merespons. '
          'Silakan coba beberapa saat lagi.',
        );

        final failure = NetworkErrorHandler.handleExceptionToFailure(exception);
        expect(failure, isA<TimeoutFailure>());
      },
    );

    test(
      'memetakan connectionError (Connection Refused) ke '
      'ConnectionRefusedException & ConnectionRefusedFailure',
      () {
        final dioError = DioException(
          requestOptions: dummyRequestOptions,
          type: DioExceptionType.connectionError,
          error: const SocketException(
            'Connection refused',
            osError: OSError('Connection refused', 111),
          ),
        );

        final exception = NetworkErrorHandler.handleDioError(dioError);
        expect(exception, isA<ConnectionRefusedException>());
        expect(
          exception.message,
          'Tidak dapat terhubung ke layanan. Silakan coba beberapa saat lagi.',
        );

        final failure = NetworkErrorHandler.handleExceptionToFailure(exception);
        expect(failure, isA<ConnectionRefusedFailure>());
        expect(
          failure.message,
          'Tidak dapat terhubung ke layanan. Silakan coba beberapa saat lagi.',
        );
      },
    );

    test(
      'memetakan connectionError (No Internet / Failed host lookup) ke '
      'NoInternetException & NoInternetFailure',
      () {
        final dioError = DioException(
          requestOptions: dummyRequestOptions,
          type: DioExceptionType.connectionError,
          message: 'Failed host lookup: api.kawalo.com',
        );

        final exception = NetworkErrorHandler.handleDioError(dioError);
        expect(exception, isA<NoInternetException>());
        expect(
          exception.message,
          'Tidak ada koneksi internet. Periksa koneksi data atau Wi-Fi Anda.',
        );

        final failure = NetworkErrorHandler.handleExceptionToFailure(exception);
        expect(failure, isA<NoInternetFailure>());
      },
    );

    test(
      'memetakan badCertificate ke SecurityException & SecurityFailure',
      () {
        final dioError = DioException(
          requestOptions: dummyRequestOptions,
          type: DioExceptionType.badCertificate,
        );

        final exception = NetworkErrorHandler.handleDioError(dioError);
        expect(exception, isA<SecurityException>());
        expect(
          exception.message,
          'Koneksi tidak aman. Silakan coba lagi nanti.',
        );

        final failure = NetworkErrorHandler.handleExceptionToFailure(exception);
        expect(failure, isA<SecurityFailure>());
      },
    );

    test(
      'memetakan respons backend StandardApiResponse dengan message & '
      'errorCode',
      () {
        final dioError = DioException(
          requestOptions: dummyRequestOptions,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: dummyRequestOptions,
            statusCode: 400,
            data: {
              'success': false,
              'message': 'Email atau password yang Anda masukkan salah',
              'error_code': 'AUTH_INVALID_CREDENTIALS',
            },
          ),
        );

        final exception = NetworkErrorHandler.handleDioError(dioError);
        expect(exception, isA<ServerException>());
        final serverEx = exception as ServerException;
        expect(
          serverEx.message,
          'Email atau password yang Anda masukkan salah',
        );
        expect(serverEx.statusCode, 400);
        expect(serverEx.errorCode, 'AUTH_INVALID_CREDENTIALS');

        final failure = NetworkErrorHandler.handleExceptionToFailure(serverEx);
        expect(failure, isA<ServerFailure>());
        final serverFail = failure as ServerFailure;
        expect(
          serverFail.message,
          'Email atau password yang Anda masukkan salah',
        );
        expect(serverFail.statusCode, 400);
        expect(serverFail.errorCode, 'AUTH_INVALID_CREDENTIALS');
      },
    );

    test(
      'menyaring error database backend agar tidak membocorkan detail teknis',
      () {
        final dioError = DioException(
          requestOptions: dummyRequestOptions,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: dummyRequestOptions,
            statusCode: 500,
            data: {
              'success': false,
              'message':
                  'PrismaClientKnownRequestError: Table tkuser does not exist',
              'error_code': 'DATABASE_ERROR',
            },
          ),
        );

        final exception = NetworkErrorHandler.handleDioError(dioError);
        expect(exception, isA<ServerException>());
        expect(
          exception.message,
          'Terjadi kendala pada sistem. Silakan coba beberapa saat lagi.',
        );
      },
    );

    test(
      'memetakan status 401 ke AuthException & AuthFailure',
      () {
        final dioError = DioException(
          requestOptions: dummyRequestOptions,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: dummyRequestOptions,
            statusCode: 401,
            data: {
              'success': false,
              'message': 'Sesi Anda telah kedaluwarsa',
              'error_code': 'AUTH_TOKEN_EXPIRED',
            },
          ),
        );

        final exception = NetworkErrorHandler.handleDioError(dioError);
        expect(exception, isA<AuthException>());
        expect(exception.message, 'Sesi Anda telah kedaluwarsa');
        expect(exception.statusCode, 401);

        final failure = NetworkErrorHandler.handleExceptionToFailure(exception);
        expect(failure, isA<AuthFailure>());
        expect(failure.message, 'Sesi Anda telah kedaluwarsa');
        expect(failure.statusCode, 401);
      },
    );

    test(
      'menggunakan fallback pesan ramah pengguna jika server tanpa JSON body',
      () {
        final dioError = DioException(
          requestOptions: dummyRequestOptions,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: dummyRequestOptions,
            statusCode: 503,
            data: 'Service Unavailable HTML page',
          ),
        );

        final exception = NetworkErrorHandler.handleDioError(dioError);
        expect(exception, isA<ServerException>());
        expect(
          exception.message,
          'Terjadi kendala pada sistem. Silakan coba beberapa saat lagi.',
        );
      },
    );

    test(
      'memetakan cancel ke RequestCancelledException & '
      'RequestCancelledFailure',
      () {
        final dioError = DioException(
          requestOptions: dummyRequestOptions,
          type: DioExceptionType.cancel,
          message: 'Request cancelled',
        );

        final exception = NetworkErrorHandler.handleDioError(dioError);
        expect(exception, isA<RequestCancelledException>());
        expect(exception.message, 'Permintaan dibatalkan.');

        final failure = NetworkErrorHandler.handleExceptionToFailure(exception);
        expect(failure, isA<RequestCancelledFailure>());
        expect(failure.message, 'Permintaan dibatalkan.');
      },
    );
  });

  group('ApiClient Timeout Configuration Tests', () {
    test(
      'ApiClient mengonfigurasi timeout sesuai AppConstants',
      () {
        final client = ApiClient(baseUrl: 'http://test.local');
        final options = client.dio.options;

        expect(options.connectTimeout, AppConstants.connectTimeout);
        expect(options.sendTimeout, AppConstants.sendTimeout);
        expect(options.receiveTimeout, AppConstants.receiveTimeout);

        expect(options.connectTimeout, const Duration(seconds: 5));
        expect(options.sendTimeout, const Duration(seconds: 15));
        expect(options.receiveTimeout, const Duration(seconds: 20));
      },
    );
  });
}
