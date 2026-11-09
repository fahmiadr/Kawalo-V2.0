import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/config/env_config.dart';
import 'package:kawalo_mobile/core/config/environment.dart';
import 'package:kawalo_mobile/core/security/jwks_service.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/core/utils/jwt_utils.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

const testPrivateKeyPem = '''
-----BEGIN PRIVATE KEY-----
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
LMKPmj14K2OD8mqf5DtSYvPno7eHfA==
-----END PRIVATE KEY-----
''';

const testPublicKeyPem = '''
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
  group('JwtUtils Tests', () {
    String buildToken(
      Map<String, dynamic> payload, {
      Map<String, dynamic>? header,
    }) {
      final headerStr = jsonEncode(header ?? {'alg': 'RS256', 'typ': 'JWT'});
      final payloadStr = jsonEncode(payload);
      final headerB64 = base64Url
          .encode(utf8.encode(headerStr))
          .replaceAll('=', '');
      final payloadB64 = base64Url
          .encode(utf8.encode(payloadStr))
          .replaceAll('=', '');
      const signatureB64 = 'mock_signature';
      return '$headerB64.$payloadB64.$signatureB64';
    }

    test('returns false when token is not expired (far future)', () {
      final futureExp = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600;
      final token = buildToken({'exp': futureExp, 'sub': 'user_1'});

      expect(JwtUtils.isExpired(token), isFalse);
    });

    test('returns true when token has expired in the past', () {
      final pastExp = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 3600;
      final token = buildToken({'exp': pastExp, 'sub': 'user_1'});

      expect(JwtUtils.isExpired(token), isTrue);
    });

    test(
      'returns true when token expires within the buffer window (clock skew)',
      () {
        final nearExp = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 30;
        final token = buildToken({'exp': nearExp, 'sub': 'user_1'});

        expect(JwtUtils.isExpired(token), isTrue);
      },
    );

    test(
      'returns false when token expires after the specified custom buffer',
      () {
        final nearExp = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 30;
        final token = buildToken({'exp': nearExp, 'sub': 'user_1'});

        // Custom buffer of 10 seconds
        expect(
          JwtUtils.isExpired(token, buffer: const Duration(seconds: 10)),
          isFalse,
        );
      },
    );

    test(
      'returns true for non-JWT string (invalid format is treated as expired)',
      () {
        expect(JwtUtils.isExpired('valid_token'), isTrue);
        expect(JwtUtils.isExpired('some_dummy_token'), isTrue);
      },
    );

    test('returns true for empty or whitespace token', () {
      expect(JwtUtils.isExpired(''), isTrue);
      expect(JwtUtils.isExpired('   '), isTrue);
    });

    test(
      'returns true for malformed 3-part token where payload is invalid base64',
      () {
        expect(JwtUtils.isExpired('header.invalid_base64!!!.sig'), isTrue);
      },
    );

    test('decodePayload successfully extracts claims from valid JWT', () {
      final exp = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600;
      final token = buildToken({
        'exp': exp,
        'sub': '123',
        'email': 'user@example.com',
        'role': 'ADMIN',
      });

      final payload = JwtUtils.decodePayload(token);
      expect(payload, isNotNull);
      expect(payload!['sub'], equals('123'));
      expect(payload['email'], equals('user@example.com'));
      expect(payload['role'], equals('ADMIN'));
      expect(payload['exp'], equals(exp));
    });

    test('decodePayload returns null for non-JWT string', () {
      expect(JwtUtils.decodePayload('not_a_jwt'), isNull);
    });

    test('decodeHeader and extractKid successfully extract header and kid', () {
      final token = buildToken(
        {'sub': 'user_1'},
        header: {'alg': 'RS256', 'typ': 'JWT', 'kid': 'kawalo-key-2026'},
      );

      final header = JwtUtils.decodeHeader(token);
      expect(header, isNotNull);
      expect(header!['alg'], equals('RS256'));
      expect(header['kid'], equals('kawalo-key-2026'));

      final kid = JwtUtils.extractKid(token);
      expect(kid, equals('kawalo-key-2026'));
    });

    test('decodeHeader and extractKid return null for malformed token', () {
      expect(JwtUtils.decodeHeader('invalid'), isNull);
      expect(JwtUtils.extractKid('invalid'), isNull);
    });

    group('verifyAndDecode RS256 Cryptographic Tests', () {
      setUp(() {
        EnvConfig.environment = AppEnvironment.dev;
        final escapedPem = testPublicKeyPem.trim().replaceAll('\n', r'\n');
        dotenv.loadFromString(
          envString:
              '''
API_BASE_URL=http://localhost:3000/api
APP_NAME=Kawalo Test
JWT_PUBLIC_KEY="$escapedPem"
''',
        );
      });

      tearDown(dotenv.clean);

      test(
        'successfully verifies and decodes genuine token signed with official '
        'RS256 key',
        () async {
          final privateKey = RSAPrivateKey(testPrivateKeyPem);
          final signer = JWT({
            'sub': 'user_123',
            'email': 'admin@kawalo.co.id',
            'name': 'Admin User',
            'role': 'ADMIN',
            'group_uid': 'GRP-001',
            'allow_admin': true,
            'allow_patrol': true,
            'allow_mon_patrol': false,
          }, issuer: 'https://api.kawalo.com');

          final token = signer.sign(privateKey, algorithm: JWTAlgorithm.RS256);

          final payload = await JwtUtils.verifyAndDecode(token);
          expect(payload, isNotNull);
          expect(payload!['sub'], equals('user_123'));
          expect(payload['role'], equals('ADMIN'));
          expect(payload['allow_admin'], equals(true));

          // Also verify synchronous method
          final syncPayload = JwtUtils.verifyAndDecodeSync(token);
          expect(syncPayload, isNotNull);
          expect(syncPayload!['sub'], equals('user_123'));
        },
      );

      test('rejects tampered token where payload was forged locally '
          '(privilege escalation attempt)', () async {
        final privateKey = RSAPrivateKey(testPrivateKeyPem);
        final signer = JWT({
          'sub': 'user_123',
          'role': 'GUARD',
        }, issuer: 'https://api.kawalo.com');
        final genuineToken = signer.sign(
          privateKey,
          algorithm: JWTAlgorithm.RS256,
        );

        final parts = genuineToken.split('.');
        final forgedPayload = base64Url
            .encode(
              utf8.encode(jsonEncode({'sub': 'user_123', 'role': 'ADMIN'})),
            )
            .replaceAll('=', '');
        final tamperedToken = '${parts[0]}.$forgedPayload.${parts[2]}';

        final result = await JwtUtils.verifyAndDecode(tamperedToken);
        expect(result, isNull);
      });

      test('rejects token with forged or modified signature', () async {
        final privateKey = RSAPrivateKey(testPrivateKeyPem);
        final signer = JWT({'sub': 'user_123', 'role': 'GUARD'});
        final genuineToken = signer.sign(
          privateKey,
          algorithm: JWTAlgorithm.RS256,
        );

        final parts = genuineToken.split('.');
        final tamperedToken = '${parts[0]}.${parts[1]}.invalid_signature';

        final result = await JwtUtils.verifyAndDecode(tamperedToken);
        expect(result, isNull);
      });

      test('returns null for empty or malformed token string', () async {
        expect(await JwtUtils.verifyAndDecode(''), isNull);
        expect(
          await JwtUtils.verifyAndDecode('not.a.valid.jwt.string'),
          isNull,
        );
      });
    });

    group('Hybrid Dynamic JWKS & Key Rotation Tests', () {
      test(
        'verifies token with kid using JwksService dynamic resolution',
        () async {
          final privateKey = RSAPrivateKey(testPrivateKeyPem.trim());

          final signer = JWT(
            {'sub': 'user_rotated', 'role': 'SUPER_ADMIN'},
            header: {'alg': 'RS256', 'typ': 'JWT', 'kid': 'rotated-key-2026'},
          );

          final token = signer.sign(privateKey, algorithm: JWTAlgorithm.RS256);

          final mockStorage = MockSecureStorageService();
          final jwksService = JwksService(storageService: mockStorage);

          final payload = await JwtUtils.verifyAndDecode(
            token,
            jwksService: jwksService,
            publicKeyPem: testPublicKeyPem,
          );

          expect(payload, isNotNull);
          expect(payload!['sub'], equals('user_rotated'));
          expect(payload['role'], equals('SUPER_ADMIN'));
        },
      );

      test(
        'checkExpiresIn false allows verifying expired authentic token',
        () async {
          final privateKey = RSAPrivateKey(testPrivateKeyPem.trim());
          final expiredExp =
              (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 3600;
          final signer = JWT({'sub': 'user_expired', 'exp': expiredExp});
          final token = signer.sign(privateKey, algorithm: JWTAlgorithm.RS256);

          // With checkExpiresIn: true (default) -> null
          final strictResult = await JwtUtils.verifyAndDecode(
            token,
            publicKeyPem: testPublicKeyPem,
          );
          expect(strictResult, isNull);

          // With checkExpiresIn: false -> payload is recovered
          final relaxedResult = await JwtUtils.verifyAndDecode(
            token,
            publicKeyPem: testPublicKeyPem,
            checkExpiresIn: false,
          );
          expect(relaxedResult, isNotNull);
          expect(relaxedResult!['sub'], equals('user_expired'));
        },
      );
    });
  });
}
