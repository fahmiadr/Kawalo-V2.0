import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/config/env_config.dart';
import 'package:kawalo_mobile/core/config/environment.dart';
import 'package:kawalo_mobile/core/security/jwks_service.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  const sampleJwk = {
    'kty': 'RSA',
    'kid': 'kawalo-key-1',
    'use': 'sig',
    'alg': 'RS256',
    'n': 't6ZwGLvl13nmBXjmgVZJeW2oZfmMAxoqtggMeMTJxHD9G2tu64579Ptw54Z8'
        '-S9eyqyehNyOjVfibuHKy2UhbyYpex8W3mE_JYxxMWZaEzpdYWaoR1L893PY'
        'Od1F88TvXSxHnwJl30gvUMoyKbZWDnwBBflmBiFWbS3WZo9Uv50=',
    'e': 'AQAB',
  };

  const rotatedJwk = {
    'kty': 'RSA',
    'kid': 'kawalo-key-2',
    'use': 'sig',
    'alg': 'RS256',
    'n': 't6ZwGLvl13nmBXjmgVZJeW2oZfmMAxoqtggMeMTJxHD9G2tu64579Ptw54Z8'
        '-S9eyqyehNyOjVfibuHKy2UhbyYpex8W3mE_JYxxMWZaEzpdYWaoR1L893PY'
        'Od1F88TvXSxHnwJl30gvUMoyKbZWDnwBBflmBiFWbS3WZo9Uv50=',
    'e': 'AQAB',
  };

  late MockSecureStorageService mockStorage;

  setUp(() {
    mockStorage = MockSecureStorageService();
    EnvConfig.environment = AppEnvironment.dev;
    dotenv.loadFromString(
      envString: r'''
API_BASE_URL=http://localhost:3000/api
APP_NAME=Kawalo Test
JWT_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAt6ZwGLvl13nmBXjmgVZJ\neW2oZfmMAxoqtggMeMTJxHD9G2tu64579Ptw54Z8-S9eyqyehNyOjVfibuHKy2Uh\nbyYpex8W3mE_JYxxMWZaEzpdYWaoR1L893PYOd1F88TvXSxHnwJl30gvUMoyKbZW\nDnwBBflmBiFWbS3WZo9Uv50CAwEAAQ==\n-----END PUBLIC KEY-----"
''',
    );
  });

  tearDown(dotenv.clean);

  group('JwksService', () {
    test('initializes and loads cached JWKS from secure storage', () async {
      final cachedJwks = jsonEncode({
        'keys': [sampleJwk],
      });
      when(() => mockStorage.getJwksCache())
          .thenAnswer((_) async => cachedJwks);

      final jwksService = JwksService(storageService: mockStorage);
      await jwksService.initialize();

      expect(jwksService.cachedKeys.containsKey('kawalo-key-1'), isTrue);
      final pem = await jwksService.getPublicKeyPemForKid('kawalo-key-1');
      expect(pem, startsWith('-----BEGIN PUBLIC KEY-----\n'));
    });

    test(
      'fetches and caches JWKS from backend when key not found in memory',
      () async {
        when(() => mockStorage.getJwksCache()).thenAnswer((_) async => null);
        when(() => mockStorage.saveJwksCache(any())).thenAnswer((_) async {});

        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.uri.path.endsWith('/.well-known/jwks.json')) {
                return handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 200,
                    data: jsonEncode({
                      'keys': [sampleJwk, rotatedJwk],
                    }),
                  ),
                );
              }
              return handler.next(options);
            },
          ),
        );

        final jwksService = JwksService(
          storageService: mockStorage,
          dio: dio,
        );

        final pem = await jwksService.getPublicKeyPemForKid('kawalo-key-2');
        expect(pem, isNotNull);
        expect(pem, startsWith('-----BEGIN PUBLIC KEY-----\n'));

        verify(() => mockStorage.saveJwksCache(any())).called(1);
      },
    );

    test(
      'falls back to EnvConfig.jwtPublicKeyPem if kid not in JWKS & net fails',
      () async {
        when(() => mockStorage.getJwksCache()).thenAnswer((_) async => null);

        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'Network unreachable',
                ),
              );
            },
          ),
        );

        final jwksService = JwksService(
          storageService: mockStorage,
          dio: dio,
        );

        final pem = await jwksService.getPublicKeyPemForKid('unknown-kid');
        expect(pem, equals(EnvConfig.jwtPublicKeyPem));
      },
    );

    test('clearCache clears in-memory and persistent storage', () async {
      final cachedJwks = jsonEncode({'keys': [sampleJwk]});
      when(() => mockStorage.getJwksCache())
          .thenAnswer((_) async => cachedJwks);
      when(() => mockStorage.clearJwksCache()).thenAnswer((_) async {});

      final jwksService = JwksService(storageService: mockStorage);
      await jwksService.initialize();

      expect(jwksService.cachedKeys.isNotEmpty, isTrue);
      await jwksService.clearCache();

      expect(jwksService.cachedKeys.isEmpty, isTrue);
      verify(() => mockStorage.clearJwksCache()).called(1);
    });
  });
}
