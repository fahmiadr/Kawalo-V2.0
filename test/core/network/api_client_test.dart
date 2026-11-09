import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockDio mockDio;
  late MockDio mockTokenDio;
  late MockSecureStorageService mockStorage;
  late ApiClient apiClient;

  setUp(() {
    mockDio = MockDio();
    mockTokenDio = MockDio();
    mockStorage = MockSecureStorageService();

    when(() => mockDio.interceptors).thenReturn(Interceptors());
    when(() => mockTokenDio.interceptors).thenReturn(Interceptors());

    apiClient = ApiClient(
      baseUrl: 'https://api.kawalo.id',
      storage: mockStorage,
      customDio: mockDio,
      customTokenDio: mockTokenDio,
    );
  });

  group('ApiClient In-Flight Deduplication Tests', () {
    test(
      'deduplicates concurrent in-flight GET requests with identical path and '
      'params',
      () async {
        when(
          () => mockDio.get<Map<String, dynamic>>(
            '/v1/guests',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return Response<Map<String, dynamic>>(
            data: <String, dynamic>{'status': 'success', 'count': 5},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/v1/guests'),
          );
        });

        final results = await Future.wait([
          apiClient.get('/v1/guests', queryParameters: {'search': 'budi'}),
          apiClient.get('/v1/guests', queryParameters: {'search': 'budi'}),
        ]);

        expect(results[0], equals({'status': 'success', 'count': 5}));
        expect(results[1], equals({'status': 'success', 'count': 5}));

        verify(
          () => mockDio.get<Map<String, dynamic>>(
            '/v1/guests',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);
      },
    );

    test(
      'deduplicates concurrent GET requests regardless of param key order',
      () async {
        when(
          () => mockDio.get<Map<String, dynamic>>(
            '/v1/attendance',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return Response<Map<String, dynamic>>(
            data: <String, dynamic>{'status': 'ok'},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/v1/attendance'),
          );
        });

        final results = await Future.wait([
          apiClient.get(
            '/v1/attendance',
            queryParameters: {'z_offset': 10, 'a_search': 'satpam'},
          ),
          apiClient.get(
            '/v1/attendance',
            queryParameters: {'a_search': 'satpam', 'z_offset': 10},
          ),
        ]);

        expect(results[0], equals({'status': 'ok'}));
        expect(results[1], equals({'status': 'ok'}));

        verify(
          () => mockDio.get<Map<String, dynamic>>(
            '/v1/attendance',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);
      },
    );

    test(
      'does not deduplicate GET requests with different parameters',
      () async {
        when(
          () => mockDio.get<Map<String, dynamic>>(
            '/v1/workers',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return Response<Map<String, dynamic>>(
            data: <String, dynamic>{'status': 'success'},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/v1/workers'),
          );
        });

        final results = await Future.wait([
          apiClient.get('/v1/workers', queryParameters: {'search': 'andi'}),
          apiClient.get('/v1/workers', queryParameters: {'search': 'budi'}),
        ]);

        expect(results[0], equals({'status': 'success'}));
        expect(results[1], equals({'status': 'success'}));

        verify(
          () => mockDio.get<Map<String, dynamic>>(
            '/v1/workers',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(2);
      },
    );

    test(
      'forwards CancelToken to Dio.get and maps DioException.cancel',
      () async {
        final token = CancelToken();

        when(
          () => mockDio.get<Map<String, dynamic>>(
            '/v1/test',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: token,
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/v1/test'),
            type: DioExceptionType.cancel,
            message: 'Request cancelled',
          ),
        );

        expect(
          () => apiClient.get('/v1/test', cancelToken: token),
          throwsA(isA<RequestCancelledException>()),
        );

        verify(
          () => mockDio.get<Map<String, dynamic>>(
            '/v1/test',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: token,
          ),
        ).called(1);
      },
    );

    test(
      'bypasses in-flight deduplication when cancelToken is provided',
      () async {
        final token1 = CancelToken();
        final token2 = CancelToken();

        when(
          () => mockDio.get<Map<String, dynamic>>(
            '/v1/items',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return Response<Map<String, dynamic>>(
            data: <String, dynamic>{'status': 'ok'},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/v1/items'),
          );
        });

        final results = await Future.wait([
          apiClient.get('/v1/items', cancelToken: token1),
          apiClient.get('/v1/items', cancelToken: token2),
        ]);

        expect(results[0], equals({'status': 'ok'}));
        expect(results[1], equals({'status': 'ok'}));

        verify(
          () => mockDio.get<Map<String, dynamic>>(
            '/v1/items',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(2);
      },
    );

    test('close closes both dio and tokenDio instances', () {
      when(() => mockDio.close(force: any(named: 'force'))).thenReturn(null);
      when(
        () => mockTokenDio.close(force: any(named: 'force')),
      ).thenReturn(null);

      apiClient.close();

      verify(() => mockDio.close()).called(1);
      verify(() => mockTokenDio.close()).called(1);
    });

    test(
      'throws ServerException when response payload has success == false',
      () async {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            '/v1/auth/login',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {
          return Response<Map<String, dynamic>>(
            data: <String, dynamic>{
              'success': false,
              'message': 'Kredensial tidak valid',
              'error_code': 'INVALID_CREDENTIALS',
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/v1/auth/login'),
          );
        });

        expect(
          () => apiClient.post('/v1/auth/login', body: {'email': 'a@b.com'}),
          throwsA(
            isA<ServerException>()
                .having((e) => e.message, 'message', 'Kredensial tidak valid')
                .having((e) => e.errorCode, 'errorCode', 'INVALID_CREDENTIALS'),
          ),
        );
      },
    );

    test('getStream bypasses deduplication and calls mockDio.get with '
        'ResponseBody', () async {
      final mockResponseBody = ResponseBody(
        Stream.fromIterable([
          Uint8List.fromList([1, 2, 3]),
        ]),
        200,
      );

      when(
        () => mockDio.get<ResponseBody>(
          '/v1/incidents/123/stream',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async {
        return Response<ResponseBody>(
          data: mockResponseBody,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/v1/incidents/123/stream'),
        );
      });

      final response1 = await apiClient.getStream('/v1/incidents/123/stream');
      final response2 = await apiClient.getStream('/v1/incidents/123/stream');

      expect(response1.statusCode, equals(200));
      expect(response2.statusCode, equals(200));

      verify(
        () => mockDio.get<ResponseBody>(
          '/v1/incidents/123/stream',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(2);
    });

    test('getStream converts DioException to AppException', () async {
      when(
        () => mockDio.get<ResponseBody>(
          '/v1/incidents/123/stream',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/incidents/123/stream'),
          type: DioExceptionType.receiveTimeout,
        ),
      );

      expect(
        () => apiClient.getStream('/v1/incidents/123/stream'),
        throwsA(isA<TimeoutException>()),
      );
    });
  });
}
