import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/security/rsa_jwk_helper.dart';

void main() {
  group('RsaJwkHelper', () {
    test(
      'converts standard RSA JWK to valid SPKI PEM readable by RSAPublicKey',
      () {
      final sampleJwk = {
        'kty': 'RSA',
        'kid': 'kawalo-key-1',
        'use': 'sig',
        'alg': 'RS256',
        'n': 't6ZwGLvl13nmBXjmgVZJeW2oZfmMAxoqtggMeMTJxHD9G2tu64579Ptw54Z8'
            '-S9eyqyehNyOjVfibuHKy2UhbyYpex8W3mE_JYxxMWZaEzpdYWaoR1L893PY'
            'Od1F88TvXSxHnwJl30gvUMoyKbZWDnwBBflmBiFWbS3WZo9Uv50=',
        'e': 'AQAB',
      };

      final pem = RsaJwkHelper.rsaJwkToPem(sampleJwk);

      expect(pem, startsWith('-----BEGIN PUBLIC KEY-----\n'));
      expect(pem, endsWith('-----END PUBLIC KEY-----\n'));

      // Must be parsed without error by RSAPublicKey
      final rsaKey = RSAPublicKey(pem);
      expect(rsaKey, isNotNull);
    });

    test('throws FormatException when n is missing or empty', () {
      expect(
        () => RsaJwkHelper.rsaJwkToPem({'kty': 'RSA', 'e': 'AQAB'}),
        throwsFormatException,
      );
      expect(
        () => RsaJwkHelper.rsaJwkToPem({'kty': 'RSA', 'n': '  ', 'e': 'AQAB'}),
        throwsFormatException,
      );
    });

    test('throws FormatException when e is missing or empty', () {
      expect(
        () => RsaJwkHelper.rsaJwkToPem({'kty': 'RSA', 'n': 'AQAB'}),
        throwsFormatException,
      );
      expect(
        () => RsaJwkHelper.rsaJwkToPem({'kty': 'RSA', 'n': 'AQAB', 'e': ' '}),
        throwsFormatException,
      );
    });

    test('throws FormatException when kty is not RSA', () {
      expect(
        () => RsaJwkHelper.rsaJwkToPem({'kty': 'EC', 'n': 'abc', 'e': 'AQAB'}),
        throwsFormatException,
      );
    });
  });
}
