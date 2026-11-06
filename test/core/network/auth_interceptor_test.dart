import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/auth_interceptor.dart';
import 'package:kawalo_mobile/core/security/jwks_service.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

const _testPrivateKeyPem = '''
-----BEGIN PRIVATE KEY-----
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
LMKPmj14K2OD8mqf5DtSYvPno7eHfA==
-----END PRIVATE KEY-----
''';

const _testPublicKeyPem = '''
-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEArr2sFaWkq3lW3qEyRyYu
u8/LCbEM/vU1j7oFfso+8Qw7djjFHdpYNn4pkgnR8qCj/GiuzeAhe2N375F0MC/E
lzNeReFQSnEbwujcgO7qxsktGLMdM0WfwXrLbmsLRD8c2K/KtlQAIj9Q8pBwXXNk
+nf66NBqSg3sA5jdEFkeR22OOJzZCzcLXOBaO3DPKUu2o86YxE3a1xI6BmFfuVXc
sVMtKeCZrk7OmowL239urYQ2Ng9AG2MK5jDgodgAOHn91qP+cw3UdGC3K2WecngW
+3xCl5E7NTXABFEsPLaotrkILCM34BfudiGXYKFZyg5oQcORDzchiQ5HGquTM7K0
rj0Vjtte2jjE7G2V/kSQX/UzpsZBdYe1oQxeFVvTgTRcfAU1FLUkUevaEe5zhUcV
WvZH9+X0P6sMEEb97wcFLlagurrtQJZhnFDuRrFMORHyXK/9/XPqCjYZMomI1qey
srHp5wuY1OP/7hy/2CGEgFPyaPAHj2wy2oBLoBS/uoRUoYLYjWqqd1xwqw4zHgA9
7UorJTKFcWzM4nAARtPjQ1pS9lY7jdXi8zNJahzvJcv8Vp9Nt0sHMnso3NH3zl1s
FJdLlJZaR5gom2Pbo+jhkFxvLZA7R1uRR2svRLvT7mcPnMbt2+FvCobza1/8wivm
BHjEMPYVLXJmBmjjEjMTTBcCAwEAAQ==
-----END PUBLIC KEY-----
''';

void main() {
  late MockDio mockDio;
  late MockDio mockTokenDio;
  late MockSecureStorageService mockStorage;
  late JwksService jwksService;
  late AuthInterceptor interceptor;
  final testRsaKey = RSAPrivateKey(_testPrivateKeyPem);

  String generateTestToken({
    String kid = 'test-key-1',
    bool isExpired = false,
  }) {
    final exp = (DateTime.now().millisecondsSinceEpoch ~/ 1000) +
        (isExpired ? -3600 : 3600);
    return JWT(
      {
        'sub': 'user_1',
        'email': 'test@example.com',
        'name': 'Test User',
        'role': 'ADMIN',
        'exp': exp,
      },
      header: {
        'alg': 'RS256',
        'typ': 'JWT',
        'kid': kid,
      },
      issuer: 'https://api.kawalo.com',
    ).sign(testRsaKey, algorithm: JWTAlgorithm.RS256);
  }

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/test'));
    registerFallbackValue(
      Response<dynamic>(requestOptions: RequestOptions(path: '/test')),
    );
    registerFallbackValue(
      DioException(requestOptions: RequestOptions(path: '/test')),
    );
  });

  setUp(() {
    final escapedPem = _testPublicKeyPem.trim().replaceAll('\n', r'\n');
    dotenv.loadFromString(
      envString: '''
API_BASE_URL=http://localhost:3000/api
APP_NAME=Kawalo Test
JWT_PUBLIC_KEY="$escapedPem"
''',
    );

    mockDio = MockDio();
    mockTokenDio = MockDio();
    mockStorage = MockSecureStorageService();
    jwksService =
        JwksService()..cacheKey('test-key-1', _testPublicKeyPem.trim());

    interceptor = AuthInterceptor(
      dio: mockDio,
      tokenDio: mockTokenDio,
      storageService: mockStorage,
      jwksService: jwksService,
    );
  });

  group('AuthInterceptor Tests', () {
    test(
        'onRequest adds Authorization header when token exists and is fresh',
        () async {
      final validFreshToken = generateTestToken();
      when(() => mockStorage.getAccessToken())
          .thenAnswer((_) async => validFreshToken);

      final options = RequestOptions(path: '/api/v1/profile');
      final handler = MockRequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], 'Bearer $validFreshToken');
      expect(options.headers['Accept'], 'application/json');
      verify(() => handler.next(options)).called(1);
      // Tidak perlu refresh karena token masih baru
      verifyNever(
        () => mockTokenDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      );
    });

    test(
        'onRequest proactively refreshes token when token is expired or '
        'near expiry (<60s)', () async {
      final expiredToken = generateTestToken(isExpired: true);
      final newProactiveToken = generateTestToken();

      when(() => mockStorage.getAccessToken())
          .thenAnswer((_) async => expiredToken);
      when(() => mockStorage.getRefreshToken())
          .thenAnswer((_) async => 'current_refresh_token');
      when(() => mockStorage.saveAccessToken(newProactiveToken))
          .thenAnswer((_) async {});
      when(() => mockStorage.saveRefreshToken('new_rotated_refresh_token'))
          .thenAnswer((_) async {});

      when(
        () => mockTokenDio.post<Map<String, dynamic>>(
          '/v1/auth/refresh',
          data: {'refresh_token': 'current_refresh_token'},
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v1/auth/refresh'),
          data: {
            'success': true,
            'data': {
              'access_token': newProactiveToken,
              'refresh_token': 'new_rotated_refresh_token',
            },
          },
        ),
      );

      final options = RequestOptions(path: '/api/v1/profile');
      final handler = MockRequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], 'Bearer $newProactiveToken');
      verify(() => handler.next(options)).called(1);
    });

    test(
        'onError on 401 refreshes, verifies and saves both access and '
        'refresh token (RTR)', () async {
      final validRefreshedAccessToken = generateTestToken();

      when(() => mockStorage.getRefreshToken())
          .thenAnswer((_) async => 'current_refresh_token');
      when(() => mockStorage.saveAccessToken(validRefreshedAccessToken))
          .thenAnswer((_) async {});
      when(() => mockStorage.saveRefreshToken('new_rotated_refresh_token'))
          .thenAnswer((_) async {});

      when(
        () => mockTokenDio.post<Map<String, dynamic>>(
          '/v1/auth/refresh',
          data: {'refresh_token': 'current_refresh_token'},
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v1/auth/refresh'),
          data: {
            'success': true,
            'data': {
              'access_token': validRefreshedAccessToken,
              'refresh_token': 'new_rotated_refresh_token',
            },
          },
        ),
      );

      final originalRequest = RequestOptions(path: '/api/v1/dashboard');
      final err = DioException(
        requestOptions: originalRequest,
        response: Response(
          requestOptions: originalRequest,
          statusCode: 401,
        ),
      );

      when(() => mockDio.fetch<dynamic>(any())).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: originalRequest,
          statusCode: 200,
          data: {'success': true},
        ),
      );

      final handler = MockErrorInterceptorHandler();
      await interceptor.onError(err, handler);

      verify(() => mockStorage.saveAccessToken(validRefreshedAccessToken))
          .called(1);
      verify(() => mockStorage.saveRefreshToken('new_rotated_refresh_token'))
          .called(1);
      verify(() => handler.resolve(any())).called(1);
    });

    test(
        'onError on 401 clears session if refreshed token fails '
        'cryptographic verification', () async {
      SessionExpiredReason? reportedReason;
      interceptor.onSessionExpired = (reason) => reportedReason = reason;

      when(() => mockStorage.getRefreshToken())
          .thenAnswer((_) async => 'current_refresh_token');
      when(() => mockStorage.clearAuthSession()).thenAnswer((_) async {});

      // Backend returns an invalid / tampered token
      when(
        () => mockTokenDio.post<Map<String, dynamic>>(
          '/v1/auth/refresh',
          data: {'refresh_token': 'current_refresh_token'},
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v1/auth/refresh'),
          data: {
            'success': true,
            'data': {
              'access_token': 'invalid.token.signature',
              'refresh_token': 'new_rotated_refresh_token',
            },
          },
        ),
      );

      final originalRequest = RequestOptions(path: '/api/v1/dashboard');
      final err = DioException(
        requestOptions: originalRequest,
        response: Response(
          requestOptions: originalRequest,
          statusCode: 401,
        ),
      );

      final handler = MockErrorInterceptorHandler();
      await interceptor.onError(err, handler);

      // Pastikan storage dibersihkan dan anomali dilaporkan
      verify(() => mockStorage.clearAuthSession()).called(1);
      expect(reportedReason, SessionExpiredReason.securityAnomaly);
      verify(() => handler.next(err)).called(1);
    });

    test('onError does NOT clear auth session on network/timeout error',
        () async {
      when(() => mockStorage.getRefreshToken())
          .thenAnswer((_) async => 'current_refresh_token');

      // Endpoint refresh mengalami timeout jaringan
      when(
        () => mockTokenDio.post<Map<String, dynamic>>(
          '/v1/auth/refresh',
          data: {'refresh_token': 'current_refresh_token'},
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/auth/refresh'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      final originalRequest = RequestOptions(path: '/api/v1/dashboard');
      final err = DioException(
        requestOptions: originalRequest,
        response: Response(
          requestOptions: originalRequest,
          statusCode: 401,
        ),
      );

      final handler = MockErrorInterceptorHandler();
      await interceptor.onError(err, handler);

      // Pastikan storage TIDAK dibersihkan saat masalah jaringan
      verifyNever(
        () => mockStorage.clearAuthSession(
          preserveEmail: any(named: 'preserveEmail'),
        ),
      );
      verify(() => handler.next(err)).called(1);
    });

    test(
        'refreshAccessToken performs single-flight deduplication on '
        'concurrent calls', () async {
      final validRefreshedToken = generateTestToken();

      when(
        () => mockTokenDio.post<Map<String, dynamic>>(
          '/v1/auth/refresh',
          data: {'refresh_token': 'shared_rft'},
        ),
      ).thenAnswer(
        (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/v1/auth/refresh'),
            data: {
              'success': true,
              'data': {
                'access_token': validRefreshedToken,
                'refresh_token': 'deduped_refresh_token',
              },
            },
          );
        },
      );
      when(() => mockStorage.saveAccessToken(validRefreshedToken))
          .thenAnswer((_) async {});
      when(() => mockStorage.saveRefreshToken('deduped_refresh_token'))
          .thenAnswer((_) async {});

      // Panggil refresh secara bersamaan dari dua pemanggil paralel
      final future1 =
          interceptor.refreshAccessToken(customRefreshToken: 'shared_rft');
      final future2 =
          interceptor.refreshAccessToken(customRefreshToken: 'shared_rft');

      final results = await Future.wait([future1, future2]);

      expect(results[0]?.accessToken, equals(validRefreshedToken));
      expect(results[1]?.accessToken, equals(validRefreshedToken));
      // Pastikan hanya SATU pemanggilan HTTP POST ke server
      verify(
        () => mockTokenDio.post<Map<String, dynamic>>(
          '/v1/auth/refresh',
          data: {'refresh_token': 'shared_rft'},
        ),
      ).called(1);
    });

    test('onRequest ignores /v1/auth/logout without proactive token refresh',
        () async {
      when(() => mockStorage.getAccessToken())
          .thenAnswer((_) async => 'logout_access_token');

      final options = RequestOptions(path: '/v1/auth/logout');
      final handler = MockRequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Accept'], 'application/json');
      expect(options.headers['Authorization'], 'Bearer logout_access_token');
      verify(() => handler.next(options)).called(1);
      verifyNever(
        () => mockTokenDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      );
    });

    test(
        'onError does not intercept 401 error on /v1/auth/logout and skips '
        'refresh', () async {
      final err = DioException(
        requestOptions: RequestOptions(path: '/v1/auth/logout'),
        response: Response(
          requestOptions: RequestOptions(path: '/v1/auth/logout'),
          statusCode: 401,
        ),
      );

      final handler = MockErrorInterceptorHandler();
      await interceptor.onError(err, handler);

      verify(() => handler.next(err)).called(1);
      verifyNever(() => mockStorage.getRefreshToken());
      verifyNever(
        () => mockTokenDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      );
    });

    test(
        'onRequest rejects request when proactive refresh fails because '
        'session was cleared', () async {
      final expiredToken = generateTestToken(isExpired: true);

      var getAccessTokenCalls = 0;
      when(() => mockStorage.getAccessToken()).thenAnswer((_) async {
        getAccessTokenCalls++;
        return getAccessTokenCalls == 1 ? expiredToken : null;
      });
      when(() => mockStorage.getRefreshToken())
          .thenAnswer((_) async => 'revoked_token');
      when(
        () => mockTokenDio.post<Map<String, dynamic>>(
          '/v1/auth/refresh',
          data: {'refresh_token': 'revoked_token'},
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/auth/refresh'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/auth/refresh'),
            statusCode: 401,
          ),
        ),
      );
      when(
        () => mockStorage.clearAuthSession(
          preserveEmail: any(named: 'preserveEmail'),
        ),
      ).thenAnswer((_) async {});

      final options = RequestOptions(path: '/api/v1/attendances');
      final handler = MockRequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      verify(
        () => handler.reject(
          any(
            that: isA<DioException>().having(
              (e) => e.response?.statusCode,
              'statusCode',
              equals(401),
            ),
          ),
        ),
      ).called(1);
    });
  });
}
