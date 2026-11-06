import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/security/jwks_service.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:kawalo_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:kawalo_mobile/features/auth/data/models/auth_session_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/auth_tokens_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/login_request_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/login_response_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/logout_request_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/refresh_token_request_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/switch_group_request_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/user_model.dart';
import 'package:kawalo_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockApiClient extends Mock implements ApiClient {}

class FakeAppCancellationToken extends Fake implements AppCancellationToken {}

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
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  final testRsaKey = RSAPrivateKey(_testPrivateKeyPem);

  String generateTestToken({bool isExpired = false}) {
    final exp = (DateTime.now().millisecondsSinceEpoch ~/ 1000) +
        (isExpired ? -3600 : 3600);
    return JWT(
      {
        'sub': 'user_1',
        'email': 'test@example.com',
        'name': 'Test User',
        'role': 'ADMIN',
        'group_uid': 'grp_1',
        'allow_admin': true,
        'allow_patrol': false,
        'allow_mon_patrol': false,
        'exp': exp,
      },
      header: {
        'alg': 'RS256',
        'typ': 'JWT',
        'kid': 'test-key-1',
      },
      issuer: 'https://api.kawalo.com',
    ).sign(testRsaKey, algorithm: JWTAlgorithm.RS256);
  }

  setUpAll(() {
    registerFallbackValue(
      const AuthTokensModel(
        accessToken: 'at',
        refreshToken: 'rt',
        tokenType: 'Bearer',
        expiresIn: 900,
      ),
    );
    registerFallbackValue(
      const UserModel(
        id: 'u1',
        email: 'e@k.com',
        name: 'u',
        groups: [],
      ),
    );
    registerFallbackValue(
      const LoginRequestModel(
        email: 'e@k.com',
        password: 'p',
      ),
    );
    registerFallbackValue(
      const LogoutRequestModel(
        refreshToken: 'rt',
      ),
    );
    registerFallbackValue(
      const RefreshTokenRequestModel(
        refreshToken: 'rt',
      ),
    );
    registerFallbackValue(
      const SwitchGroupRequestModel(
        groupUid: 'g1',
      ),
    );
    registerFallbackValue(
      const AuthSessionModel(
        userId: 'u1',
        email: 'e@k.com',
        name: 'u',
        allowAdmin: false,
        allowPatrol: false,
        allowMonPatrol: false,
      ),
    );
    registerFallbackValue(FakeAppCancellationToken());
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
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    when(
      () => mockLocalDataSource.clearSession(
        preserveEmail: any(named: 'preserveEmail'),
      ),
    ).thenAnswer((_) async => {});
    when(() => mockLocalDataSource.saveLastEmail(any()))
        .thenAnswer((_) async => {});
    when(() => mockLocalDataSource.saveSession(any()))
        .thenAnswer((_) async => {});

    final testJwks = JwksService()
      ..cacheKey('test-key-1', _testPublicKeyPem.trim());

    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      jwksService: testJwks,
    );
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tUserModel = UserModel(
    id: 'user_1',
    email: tEmail,
    name: 'Test User',
    groups: [],
  );
  const tUserEntity = UserEntity(
    id: 'user_1',
    email: tEmail,
    name: 'Test User',
    groups: [],
  );

  AuthTokensModel createValidTokens() {
    return AuthTokensModel(
      accessToken: generateTestToken(),
      refreshToken: 'mock_refresh_token',
      tokenType: 'Bearer',
      expiresIn: 900,
    );
  }

  group('login', () {
    test(
      'should return UserEntity and save tokens & user when remote call '
      'succeeds',
      () async {
        // Arrange
        final validTokens = createValidTokens();
        final loginResponse = LoginResponseModel(
          user: tUserModel,
          tokens: validTokens,
        );
        when(() => mockRemoteDataSource.login(any()))
            .thenAnswer((_) async => loginResponse);
        when(() => mockLocalDataSource.saveTokens(any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.saveUser(any()))
            .thenAnswer((_) async => {});

        // Act
        final result =
            await repository.login(email: tEmail, password: tPassword);

        // Assert
        expect(result, const Right<Failure, UserEntity>(tUserEntity));
        verify(
          () => mockRemoteDataSource.login(
            const LoginRequestModel(email: tEmail, password: tPassword),
          ),
        ).called(1);
        verify(() => mockLocalDataSource.saveTokens(validTokens)).called(1);
        verify(() => mockLocalDataSource.saveUser(tUserModel)).called(1);
        verify(() => mockLocalDataSource.saveSession(any())).called(1);
        verify(() => mockLocalDataSource.saveLastEmail(tEmail)).called(1);
      },
    );

    test(
      'should return ServerFailure when remote data source throws '
      'ServerException',
      () async {
        // Arrange
        when(() => mockRemoteDataSource.login(any()))
            .thenThrow(const ServerException('Server Exception', 500));

        // Act
        final result =
            await repository.login(email: tEmail, password: tPassword);

        // Assert
        expect(
          result,
          const Left<Failure, UserEntity>(
            ServerFailure('Server Exception', 500),
          ),
        );
        verify(
          () => mockRemoteDataSource.login(
            const LoginRequestModel(email: tEmail, password: tPassword),
          ),
        ).called(1);
        verifyNever(() => mockLocalDataSource.saveTokens(any()));
      },
    );
  });

  group('logout', () {
    test(
      'should clear local session and revoke token on remote when called',
      () async {
        // Arrange
        when(() => mockLocalDataSource.getRefreshToken())
            .thenAnswer((_) async => 'mock_refresh_token');
        when(() => mockRemoteDataSource.logout(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.logout();

        // Assert
        expect(result, const Right<Failure, void>(null));
        verify(() => mockLocalDataSource.getRefreshToken()).called(1);
        verify(
          () => mockRemoteDataSource.logout(
            const LogoutRequestModel(refreshToken: 'mock_refresh_token'),
          ),
        ).called(1);
        verify(() => mockLocalDataSource.clearSession(preserveEmail: false))
            .called(1);
      },
    );
  });

  group('getCurrentUser', () {
    String buildExpiredJwt() {
      return generateTestToken(isExpired: true);
    }

    test(
      'should return UserEntity when user exists and access token is valid',
      () async {
        // Arrange
        final validToken = generateTestToken();
        when(() => mockLocalDataSource.getUser())
            .thenAnswer((_) async => tUserModel);
        when(() => mockLocalDataSource.getAccessToken())
            .thenAnswer((_) async => validToken);
        when(() => mockLocalDataSource.getRefreshToken())
            .thenAnswer((_) async => 'mock_refresh_token');

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, const Right<Failure, UserEntity?>(tUserEntity));
        verify(() => mockLocalDataSource.getUser()).called(1);
        verify(() => mockLocalDataSource.getAccessToken()).called(1);
        verify(() => mockLocalDataSource.saveSession(any())).called(1);
      },
    );

    test('should return null when no cached user is present', () async {
      // Arrange
      when(() => mockLocalDataSource.getUser())
          .thenAnswer((_) async => null);
      when(() => mockLocalDataSource.getAccessToken())
          .thenAnswer((_) async => null);
      when(() => mockLocalDataSource.getRefreshToken())
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result, const Right<Failure, UserEntity?>(null));
      verify(() => mockLocalDataSource.getUser()).called(1);
    });

    test('should return null when user exists but tokens are missing',
        () async {
      // Arrange
      when(() => mockLocalDataSource.getUser())
          .thenAnswer((_) async => tUserModel);
      when(() => mockLocalDataSource.getAccessToken())
          .thenAnswer((_) async => null);
      when(() => mockLocalDataSource.getRefreshToken())
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result, const Right<Failure, UserEntity?>(null));
      verify(() => mockLocalDataSource.getUser()).called(1);
    });

    test(
      'should silently refresh token when access token is expired and return '
      'user',
      () async {
        // Arrange
        final expiredJwt = buildExpiredJwt();
        final refreshedTokens = createValidTokens();
        when(() => mockLocalDataSource.getUser())
            .thenAnswer((_) async => tUserModel);
        when(() => mockLocalDataSource.getAccessToken())
            .thenAnswer((_) async => expiredJwt);
        when(() => mockLocalDataSource.getRefreshToken())
            .thenAnswer((_) async => 'mock_refresh_token');
        when(
          () => mockRemoteDataSource.refreshToken(
            any(),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => refreshedTokens);
        when(() => mockLocalDataSource.saveTokens(refreshedTokens))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, const Right<Failure, UserEntity?>(tUserEntity));
        verify(
          () => mockRemoteDataSource.refreshToken(
            const RefreshTokenRequestModel(refreshToken: 'mock_refresh_token'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);
        verify(() => mockLocalDataSource.saveTokens(refreshedTokens)).called(1);
      },
    );

    test(
      'should silently refresh token via ApiClient when apiClient is injected',
      () async {
        final mockApiClient = MockApiClient();
        final repoWithClient = AuthRepositoryImpl(
          remoteDataSource: mockRemoteDataSource,
          localDataSource: mockLocalDataSource,
          apiClient: mockApiClient,
        );

        final expiredJwt = buildExpiredJwt();
        final refreshedJwt = generateTestToken();
        when(() => mockLocalDataSource.getUser())
            .thenAnswer((_) async => tUserModel);
        when(() => mockLocalDataSource.getAccessToken())
            .thenAnswer((_) async => expiredJwt);
        when(() => mockLocalDataSource.getRefreshToken())
            .thenAnswer((_) async => 'mock_refresh_token');
        when(
          () => mockApiClient.refreshAccessToken(
            refreshToken: any(named: 'refreshToken'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => (
            accessToken: refreshedJwt,
            refreshToken: 'new_refresh_token',
          ),
        );
        when(() => mockLocalDataSource.saveTokens(any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.saveSession(any()))
            .thenAnswer((_) async => {});

        final result = await repoWithClient.getCurrentUser();

        expect(result, const Right<Failure, UserEntity?>(tUserEntity));
        verify(
          () => mockApiClient.refreshAccessToken(
            refreshToken: 'mock_refresh_token',
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);
        verifyNever(
          () => mockRemoteDataSource.refreshToken(
            any(),
            cancelToken: any(named: 'cancelToken'),
          ),
        );
      },
    );

    test(
      'should retain cached user when refresh token times out and triggers '
      'cancellation',
      () async {
        final expiredJwt = buildExpiredJwt();
        when(() => mockLocalDataSource.getUser())
            .thenAnswer((_) async => tUserModel);
        when(() => mockLocalDataSource.getAccessToken())
            .thenAnswer((_) async => expiredJwt);
        when(() => mockLocalDataSource.getRefreshToken())
            .thenAnswer((_) async => 'mock_refresh_token');
        when(
          () => mockRemoteDataSource.refreshToken(
            any(),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (invocation) async {
            final token = invocation.namedArguments[#cancelToken]
                as AppCancellationToken?;
            await Future<void>.delayed(const Duration(milliseconds: 100));
            if (token?.isCancelled ?? false) {
              throw const AuthException('Permintaan dibatalkan.');
            }
            return createValidTokens();
          },
        );

        final result = await repository.getCurrentUser();

        expect(result, const Right<Failure, UserEntity?>(tUserEntity));
      },
    );

    test(
      'should clear session and return null when access token is expired and '
      'refresh token returns 401',
      () async {
        // Arrange
        final expiredJwt = buildExpiredJwt();
        when(() => mockLocalDataSource.getUser())
            .thenAnswer((_) async => tUserModel);
        when(() => mockLocalDataSource.getAccessToken())
            .thenAnswer((_) async => expiredJwt);
        when(() => mockLocalDataSource.getRefreshToken())
            .thenAnswer((_) async => 'mock_refresh_token');
        when(
          () => mockRemoteDataSource.refreshToken(
            any(),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const ServerException('Unauthorized', 401));

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, const Right<Failure, UserEntity?>(null));
        verify(() => mockLocalDataSource.clearSession()).called(1);
      },
    );

    test(
      'should retain cached user when access token is expired but refresh '
      'token encounters network error',
      () async {
        // Arrange
        final expiredJwt = buildExpiredJwt();
        when(() => mockLocalDataSource.getUser())
            .thenAnswer((_) async => tUserModel);
        when(() => mockLocalDataSource.getAccessToken())
            .thenAnswer((_) async => expiredJwt);
        when(() => mockLocalDataSource.getRefreshToken())
            .thenAnswer((_) async => 'mock_refresh_token');
        when(
          () => mockRemoteDataSource.refreshToken(
            any(),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const NoInternetException());

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, const Right<Failure, UserEntity?>(tUserEntity));
        verifyNever(() => mockLocalDataSource.clearSession());
      },
    );
  });

  group('getActiveSession', () {
    const tSessionModel = AuthSessionModel(
      userId: 'user_1',
      email: tEmail,
      name: 'Test User',
      role: 'ADMIN',
      groupUid: 'g1',
      allowAdmin: true,
      allowPatrol: false,
      allowMonPatrol: false,
    );

    const tSessionEntity = AuthSessionEntity(
      userId: 'user_1',
      email: tEmail,
      name: 'Test User',
      role: 'ADMIN',
      groupUid: 'g1',
      allowAdmin: true,
      allowPatrol: false,
      allowMonPatrol: false,
    );

    test('should return AuthSessionEntity when session exists in local storage',
        () async {
      when(() => mockLocalDataSource.getSession())
          .thenAnswer((_) async => tSessionModel);

      final result = await repository.getActiveSession();

      expect(
        result,
        const Right<Failure, AuthSessionEntity?>(tSessionEntity),
      );
      verify(() => mockLocalDataSource.getSession()).called(1);
    });

    test('should return null when no session is found in local storage',
        () async {
      when(() => mockLocalDataSource.getSession())
          .thenAnswer((_) async => null);

      final result = await repository.getActiveSession();

      expect(result, const Right<Failure, AuthSessionEntity?>(null));
      verify(() => mockLocalDataSource.getSession()).called(1);
    });
  });
}
