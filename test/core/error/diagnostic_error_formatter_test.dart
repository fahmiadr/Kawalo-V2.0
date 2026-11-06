import 'dart:async' as async;
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/diagnostic_error_formatter.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';

void main() {
  group('DiagnosticErrorFormatter Strategy Tests', () {
    group('DevDiagnosticErrorFormatter', () {
      const formatter = DevDiagnosticErrorFormatter();

      test('formats CameraException with code and description', () {
        final error = CameraException(
          'CameraAccessDenied',
          'Permission denied',
        );
        final result = formatter.format(error);
        expect(
          result,
          equals(
            'CameraException(code: CameraAccessDenied, '
            'description: Permission denied)',
          ),
        );
      });

      test('formats general error using toString()', () {
        final error = StateError('Internal buffer corrupted');
        final result = formatter.format(error);
        expect(result, equals('Bad state: Internal buffer corrupted'));
      });
    });

    group('ProductionDiagnosticErrorFormatter (Project-Wide Standard)', () {
      const formatter = ProductionDiagnosticErrorFormatter();

      test('normalizes CameraException code to standard uppercase token', () {
        expect(
          formatter.format(CameraException('CameraAccessDenied', 'desc')),
          equals('Kode: CAM_ACCESS_DENIED'),
        );
        expect(
          formatter.format(CameraException('CameraInUse', 'desc')),
          equals('Kode: CAM_IN_USE'),
        );
        expect(
          formatter.format(
            CameraException('cameraExclusiveAccessFailed', 'desc'),
          ),
          equals('Kode: CAM_EXCLUSIVE_ACCESS_FAILED'),
        );
        expect(
          formatter.format(CameraException('error', 'desc')),
          equals('Kode: CAM_ERROR'),
        );
      });

      test('sanitizes FileSystemException and strips absolute paths', () {
        const sensitivePath =
            '/data/user/0/id.kawalo.app/cache/camera/foto_kamera.jpg';
        const error = FileSystemException(
          'Cannot open file',
          sensitivePath,
          OSError('No space left on device', 28),
        );

        final result = formatter.format(error);
        expect(
          result,
          equals('Kode: STORAGE_IO_ERROR [28] (No space left on device)'),
        );
        expect(result.contains('/data/user/0'), isFalse);
        expect(result.contains(sensitivePath), isFalse);
      });

      test('handles FileSystemException without OSError cleanly without paths',
          () {
        const sensitivePath = '/storage/emulated/0/DCIM/photo.jpg';
        const error = FileSystemException('Write failed', sensitivePath);

        final result = formatter.format(error);
        expect(result, equals('Kode: STORAGE_IO_ERROR (Write failed)'));
        expect(result.contains('/storage/emulated/0'), isFalse);
      });

      test(
        'sanitizes PlatformException and masks internal paths in message',
        () {
          final error = PlatformException(
            code: 'CAMERA_DISCONNECTED',
            message: 'Hardware disconnected at /sys/devices/platform/camera',
          );

          final result = formatter.format(error);
          expect(
            result,
            equals(
              'Kode: PLATFORM_CAMERA_DISCONNECTED '
              '(Hardware disconnected at [path])',
            ),
          );
          expect(result.contains('/sys/devices'), isFalse);
        },
      );

      test(
        'normalizes PlatformException code with slashes, colons, and spaces',
        () {
          final error = PlatformException(
            code: 'camera/unsupported:device error',
          );
          expect(
            formatter.format(error),
            equals('Kode: PLATFORM_CAMERA_UNSUPPORTED_DEVICE_ERROR'),
          );
        },
      );

      test('formats TimeoutException to NET_TIMEOUT', () {
        const error = TimeoutException('Connection timeout');
        expect(formatter.format(error), equals('Kode: NET_TIMEOUT'));
      });

      test('formats dart:async TimeoutException to NET_TIMEOUT', () {
        final error = async.TimeoutException('Future timeout expired');
        expect(formatter.format(error), equals('Kode: NET_TIMEOUT'));
      });

      test('formats ServerException with status code and error code', () {
        const error = ServerException(
          'Internal server error',
          500,
          'INTERNAL_ERROR',
        );
        expect(
          formatter.format(error),
          equals('Kode: SRV_INTERNAL_ERROR [500]'),
        );
      });

      test(
        'formats ServerException with empty errorCode without trailing '
        'underscore',
        () {
          const error = ServerException('Internal server error', 500, '');
          expect(
            formatter.format(error),
            equals('Kode: SRV [500]'),
          );
        },
      );

      test('formats Network exceptions to appropriate domain tokens', () {
        expect(
          formatter.format(const NoInternetException()),
          equals('Kode: NET_NO_INTERNET'),
        );
        expect(
          formatter.format(const ConnectionRefusedException()),
          equals('Kode: NET_CONN_REFUSED'),
        );
        expect(
          formatter.format(const NetworkException('Offline', 503)),
          equals('Kode: NET_ERROR [503]'),
        );
      });

      test('formats AuthException with status code', () {
        expect(
          formatter.format(const AuthException()),
          equals('Kode: AUTH_SESSION_EXPIRED [401]'),
        );
      });

      test('formats SecurityException to SEC_TLS_ERROR', () {
        expect(
          formatter.format(const SecurityException()),
          equals('Kode: SEC_TLS_ERROR'),
        );
      });

      test('formats ConfigurationSecurityException to SEC_CONFIG_ERROR', () {
        const error = ConfigurationSecurityException('Insecure SSL pinned');
        expect(
          formatter.format(error),
          equals('Kode: SEC_CONFIG_ERROR'),
        );
      });

      test('formats CacheException to STORAGE_CACHE_ERROR', () {
        expect(
          formatter.format(const CacheException()),
          equals('Kode: STORAGE_CACHE_ERROR'),
        );
      });

      test('formats RequestCancelledException to NET_CANCELLED', () {
        expect(
          formatter.format(const RequestCancelledException()),
          equals('Kode: NET_CANCELLED'),
        );
      });

      test('does not misclassify raw SocketException as storage error', () {
        const error = SocketException('Network is unreachable');
        final result = formatter.format(error, domainPrefix: 'NET');
        expect(result, equals('Kode: NET_UNEXPECTED (SocketException)'));
        expect(result.contains('STORAGE_IO_ERROR'), isFalse);
      });

      test('formats general unexpected error using safe runtime type name', () {
        final error = StateError('Corrupted buffer');
        expect(
          formatter.format(error, domainPrefix: 'CAM'),
          equals('Kode: CAM_UNEXPECTED (StateError)'),
        );
        expect(
          formatter.format(error),
          equals('Kode: ERR_UNEXPECTED (StateError)'),
        );
      });

      test('normalizes empty or whitespace domainPrefix to fallback ERR', () {
        final error = StateError('Corrupted buffer');
        expect(
          formatter.format(error, domainPrefix: ''),
          equals('Kode: ERR_UNEXPECTED (StateError)'),
        );
        expect(
          formatter.format(error, domainPrefix: '   '),
          equals('Kode: ERR_UNEXPECTED (StateError)'),
        );
      });
    });

    group(
      'DefaultDiagnosticErrorFormatter (Pure DI & Strategy Resolution)',
      () {
        test(
          'resolves to DevDiagnosticErrorFormatter when isProduction is false',
          () {
            const formatter =
                DefaultDiagnosticErrorFormatter(isProduction: false);
            final error = StateError('Debug info');
            expect(formatter.format(error), equals('Bad state: Debug info'));
          },
        );

        test(
          'resolves to ProductionDiagnosticErrorFormatter when isProduction '
          'is true',
          () {
            const formatter =
                DefaultDiagnosticErrorFormatter(isProduction: true);
            final error = StateError('Debug info');
            expect(
              formatter.format(error, domainPrefix: 'CAM'),
              equals('Kode: CAM_UNEXPECTED (StateError)'),
            );
          },
        );

      },
    );

    group('DiagnosticErrorFormatter.formatError (Central Facade)', () {
      test('formats error directly via static helper for production', () {
        const error = NoInternetException();
        final result = DiagnosticErrorFormatter.formatError(
          error,
          isProduction: true,
        );
        expect(result, equals('Kode: NET_NO_INTERNET'));
      });

      test('formats error directly via static helper for development', () {
        final error = StateError('Dev trace');
        final result = DiagnosticErrorFormatter.formatError(
          error,
          isProduction: false,
        );
        expect(result, equals('Bad state: Dev trace'));
      });

      test('respects formatter when provided to formatError (Pure DI / DIP)',
          () {
        final result = DiagnosticErrorFormatter.formatError(
          Exception('Any error'),
          formatter: const _StubDiagnosticFormatter(),
        );
        expect(result, equals('CUSTOM_STUB_TOKEN'));
      });
    });
  });
}

class _StubDiagnosticFormatter implements DiagnosticErrorFormatter {
  const _StubDiagnosticFormatter();

  @override
  String format(Object error, {String? domainPrefix}) {
    return 'CUSTOM_STUB_TOKEN';
  }
}
