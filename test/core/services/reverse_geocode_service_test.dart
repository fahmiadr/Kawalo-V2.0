import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late OsmNominatimReverseGeocodeService service;

  setUp(() {
    mockDio = MockDio();
    service = OsmNominatimReverseGeocodeService(dio: mockDio);
  });

  group('ReverseGeocodeResult Value Object Tests', () {
    test('supports value equality via Equatable', () {
      const result1 = ReverseGeocodeResult.success(
        latitude: -6.2,
        longitude: 106.8,
        address: 'Jl. Sudirman',
      );
      const result2 = ReverseGeocodeResult.success(
        latitude: -6.2,
        longitude: 106.8,
        address: 'Jl. Sudirman',
      );
      const result3 = ReverseGeocodeResult.failure(
        latitude: -6.2,
        longitude: 106.8,
        status: ReverseGeocodeStatus.networkError,
        errorMessage: 'Network error',
      );

      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
      expect(result1.coordinates, equals((-6.2, 106.8)));
      expect(result1.isSuccess, isTrue);
      expect(result1.isFailure, isFalse);
      expect(result1.isCancelled, isFalse);
    });

    test('copyWith updates fields and preserves null with sentinel', () {
      const original = ReverseGeocodeResult.success(
        latitude: -6.2,
        longitude: 106.8,
        address: 'Jl. Sudirman',
      );

      final updated = original.copyWith(
        status: ReverseGeocodeStatus.noResult,
        address: null,
      );

      expect(updated.status, equals(ReverseGeocodeStatus.noResult));
      expect(updated.address, isNull);
      expect(updated.latitude, equals(-6.2));
      expect(updated.longitude, equals(106.8));
    });
  });

  group('OsmNominatimReverseGeocodeService Tests', () {
    test('returns formatted Indonesian address with success status', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{
            'address': <String, dynamic>{
              'road': 'Jl. Jenderal Sudirman',
              'suburb': 'Karet Semanggi',
              'city': 'Jakarta Selatan',
              'state': 'DKI Jakarta',
            },
            'display_name': 'Jl. Jenderal Sudirman, Jakarta Selatan',
          },
          requestOptions: RequestOptions(
            path: 'https://nominatim.openstreetmap.org/reverse',
          ),
          statusCode: 200,
        ),
      );

      final result = await service.reverseGeocode(
        latitude: -6.2215,
        longitude: 106.8174,
      );

      expect(result.status, equals(ReverseGeocodeStatus.success));
      expect(
        result.address,
        equals(
          'Jl. Jenderal Sudirman, Karet Semanggi, Jakarta Selatan, DKI Jakarta',
        ),
      );
      expect(result.isSuccess, isTrue);
    });

    test('falls back to display_name when address details are missing',
        () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{
            'display_name': 'Kawasan Konservasi Hutan Lindung, Jawa Barat',
          },
          requestOptions: RequestOptions(
            path: 'https://nominatim.openstreetmap.org/reverse',
          ),
          statusCode: 200,
        ),
      );

      final result = await service.reverseGeocode(
        latitude: -6.789123,
        longitude: 107.123456,
      );

      expect(result.status, equals(ReverseGeocodeStatus.success));
      expect(
        result.address,
        equals('Kawasan Konservasi Hutan Lindung, Jawa Barat'),
      );
    });

    test('returns noResult when response data is null or empty', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(
            path: 'https://nominatim.openstreetmap.org/reverse',
          ),
          statusCode: 200,
        ),
      );

      final result = await service.reverseGeocode(
        latitude: -6,
        longitude: 106,
      );

      expect(result.status, equals(ReverseGeocodeStatus.noResult));
      expect(result.address, isNull);
    });

    test('returns cached result without calling Dio twice', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{
            'address': <String, dynamic>{
              'road': 'Jl. Gatot Subroto',
              'city': 'Jakarta Selatan',
            },
          },
          requestOptions: RequestOptions(
            path: 'https://nominatim.openstreetmap.org/reverse',
          ),
          statusCode: 200,
        ),
      );

      final first = await service.reverseGeocode(
        latitude: -6.230000,
        longitude: 106.820000,
      );
      final second = await service.reverseGeocode(
        latitude: -6.230000,
        longitude: 106.820000,
      );

      expect(first.address, equals('Jl. Gatot Subroto, Jakarta Selatan'));
      expect(second.address, equals('Jl. Gatot Subroto, Jakarta Selatan'));
      expect(first, equals(second));

      verify(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(1);
    });

    test('clearCache empties in-memory cache and re-queries Dio', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{
            'display_name': 'Titik Lokasi Baru',
          },
          requestOptions: RequestOptions(
            path: 'https://nominatim.openstreetmap.org/reverse',
          ),
          statusCode: 200,
        ),
      );

      await service.reverseGeocode(latitude: -6.100000, longitude: 106.900000);
      service.clearCache();
      await service.reverseGeocode(latitude: -6.100000, longitude: 106.900000);

      verify(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(2);
    });

    test('evicts oldest entries when LRU maxCacheEntries is reached', () async {
      final smallCacheService = OsmNominatimReverseGeocodeService(
        dio: mockDio,
        maxCacheEntries: 2,
      );

      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (invocation) async {
          final query = invocation.namedArguments[#queryParameters]
              as Map<String, dynamic>;
          final lat = query['lat'] as double;
          return Response<Map<String, dynamic>>(
            data: <String, dynamic>{
              'display_name': 'Lokasi $lat',
            },
            requestOptions: RequestOptions(
              path: 'https://nominatim.openstreetmap.org/reverse',
            ),
            statusCode: 200,
          );
        },
      );

      // Query 1 and 2 (cache holds [1, 2])
      await smallCacheService.reverseGeocode(latitude: 1, longitude: 1);
      await smallCacheService.reverseGeocode(latitude: 2, longitude: 2);

      // Query 3 (cache evicts 1, holds [2, 3])
      await smallCacheService.reverseGeocode(latitude: 3, longitude: 3);

      // Query 2 again (should hit cache)
      await smallCacheService.reverseGeocode(latitude: 2, longitude: 2);

      // Query 1 again (should re-query Dio because it was evicted)
      await smallCacheService.reverseGeocode(latitude: 1, longitude: 1);

      // Total calls: lat 1 called twice, lat 2 called once, lat 3 called once
      verify(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(4);
    });

    test('deduplicates concurrent in-flight requests for identical coordinates',
        () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return Response<Map<String, dynamic>>(
            data: <String, dynamic>{
              'address': <String, dynamic>{
                'road': 'Jl. Asia Afrika',
                'city': 'Bandung',
              },
            },
            requestOptions: RequestOptions(
              path: 'https://nominatim.openstreetmap.org/reverse',
            ),
            statusCode: 200,
          );
        },
      );

      final results = await Future.wait([
        service.reverseGeocode(latitude: -6.920000, longitude: 107.610000),
        service.reverseGeocode(latitude: -6.920000, longitude: 107.610000),
      ]);

      expect(results[0].address, equals('Jl. Asia Afrika, Bandung'));
      expect(results[1].address, equals('Jl. Asia Afrika, Bandung'));

      verify(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(1);
    });

    test('handles cancel token and returns cancelled status', () async {
      final token = DioCancellationToken();

      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async {
        throw DioException(
          requestOptions: RequestOptions(
            path: 'https://nominatim.openstreetmap.org/reverse',
          ),
          type: DioExceptionType.cancel,
          error: 'Operasi dibatalkan',
        );
      });

      final result = await service.reverseGeocode(
        latitude: -6.200000,
        longitude: 106.800000,
        cancelToken: token,
      );

      expect(result.status, equals(ReverseGeocodeStatus.cancelled));
      expect(result.isCancelled, isTrue);
      expect(result.isFailure, isFalse);
    });

    test('handles connection timeout and returns timeout failure status',
        () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: 'https://nominatim.openstreetmap.org/reverse',
          ),
          type: DioExceptionType.connectionTimeout,
          error: 'Connection timeout',
        ),
      );

      final result = await service.reverseGeocode(
        latitude: -7.111111,
        longitude: 110.222222,
      );

      expect(result.status, equals(ReverseGeocodeStatus.timeout));
      expect(result.isFailure, isTrue);
      expect(result.address, isNull);
    });

    test('handles HTTP 429 rate limit and returns rateLimited status',
        () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: 'https://nominatim.openstreetmap.org/reverse',
          ),
          response: Response(
            statusCode: 429,
            requestOptions: RequestOptions(
              path: 'https://nominatim.openstreetmap.org/reverse',
            ),
          ),
        ),
      );

      final result = await service.reverseGeocode(
        latitude: -7.111111,
        longitude: 110.222222,
      );

      expect(result.status, equals(ReverseGeocodeStatus.rateLimited));
      expect(result.isFailure, isTrue);
    });

    test('handles generic DioException and returns networkError status',
        () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: 'https://nominatim.openstreetmap.org/reverse',
          ),
          error: 'SocketException',
        ),
      );

      final result = await service.reverseGeocode(
        latitude: -7.111111,
        longitude: 110.222222,
      );

      expect(result.status, equals(ReverseGeocodeStatus.networkError));
      expect(result.isFailure, isTrue);
    });

    test('instance getters provide singleton instance', () {
      expect(
        ReverseGeocodeService.instance,
        isA<ReverseGeocodeService>(),
      );
      expect(
        OsmNominatimReverseGeocodeService.instance,
        isA<OsmNominatimReverseGeocodeService>(),
      );
    });
  });
}
