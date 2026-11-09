import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/network/api_response_model.dart';

void main() {
  group('ApiResponseModel Tests', () {
    test('parses success envelope correctly with generic data', () {
      final json = {
        'success': true,
        'message': 'Data berhasil dimuat',
        'data': {'id': 1, 'name': 'Kawalo'},
      };

      final response = ApiResponseModel<Map<String, dynamic>>.fromJson(
        json,
        (data) => data! as Map<String, dynamic>,
      );

      expect(response.success, isTrue);
      expect(response.message, 'Data berhasil dimuat');
      expect(response.data?['id'], 1);
      expect(response.data?['name'], 'Kawalo');
    });

    test('defaults message to empty string when missing in response', () {
      final json = {'success': true, 'data': 'payload'};

      final response = ApiResponseModel<String>.fromJson(
        json,
        (data) => data! as String,
      );

      expect(response.message, '');
      expect(response.data, 'payload');
    });

    test('parses error envelope with error_code and details', () {
      final json = {
        'success': false,
        'message': 'Akses ditolak',
        'error_code': 'FORBIDDEN',
        'details': {'reason': 'Role insufficient'},
      };

      final response = ApiResponseModel<Object?>.fromJson(json, (_) => null);

      expect(response.success, isFalse);
      expect(response.message, 'Akses ditolak');
      expect(response.errorCode, 'FORBIDDEN');
      expect(response.details, {'reason': 'Role insufficient'});
      expect(response.data, isNull);
    });

    test('throws FormatException if success field is not a boolean', () {
      final json = {'success': 'true', 'message': 'OK', 'data': null};

      expect(
        () => ApiResponseModel<Object?>.fromJson(json, (_) => null),
        throwsFormatException,
      );
    });

    test('unwrap returns payload when success is true and data exists', () {
      final json = {
        'success': true,
        'message': 'OK',
        'data': {'count': 10},
      };

      final result = ApiResponseModel.unwrap(
        json,
        (data) => (data! as Map<String, dynamic>)['count'] as int,
      );

      expect(result, equals(10));
    });

    test('unwrap throws ServerException when success is false', () {
      final json = {
        'success': false,
        'message': 'Terjadi kesalahan sistem',
        'error_code': 'SYSTEM_ERROR',
      };

      expect(
        () => ApiResponseModel.unwrap(json, (data) => data),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Terjadi kesalahan sistem',
          ),
        ),
      );
    });

    test(
      'unwrap throws ServerException when data is null for non-nullable T',
      () {
        final json = {'success': true, 'message': 'OK', 'data': null};

        expect(
          () =>
              ApiResponseModel.unwrap<String>(json, (data) => data! as String),
          throwsA(isA<ServerException>()),
        );
      },
    );

    test('props equality compares models correctly', () {
      const resp1 = ApiResponseModel<String>(
        success: true,
        message: 'Sukses',
        data: 'a',
      );
      const resp2 = ApiResponseModel<String>(
        success: true,
        message: 'Sukses',
        data: 'a',
      );
      const resp3 = ApiResponseModel<String>(
        success: true,
        message: 'Sukses',
        data: 'b',
      );
      expect(resp1, equals(resp2));
      expect(resp1, isNot(equals(resp3)));

      const err1 = ApiResponseModel<void>(
        success: false,
        message: 'Gagal',
        errorCode: 'ERR',
      );
      const err2 = ApiResponseModel<void>(
        success: false,
        message: 'Gagal',
        errorCode: 'ERR',
      );
      expect(err1, equals(err2));
    });
  });
}
