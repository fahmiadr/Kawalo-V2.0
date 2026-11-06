import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/auth/data/models/auth_tokens_model.dart';

void main() {
  group('AuthTokensModel Tests', () {
    test(
      'fromJson deserializes JSON map directly into AuthTokensModel',
      () {
        final json = {
          'access_token': 'jwt_access_token',
          'refresh_token': 'opaque_refresh_token',
          'token_type': 'Bearer',
          'expires_in': 900,
        };

        final model = AuthTokensModel.fromJson(json);

        expect(model.accessToken, equals('jwt_access_token'));
        expect(model.refreshToken, equals('opaque_refresh_token'));
        expect(model.tokenType, equals('Bearer'));
        expect(model.expiresIn, equals(900));
      },
    );

    test('props equality compares models correctly', () {
      const m1 = AuthTokensModel(
        accessToken: 'a',
        refreshToken: 'r',
        tokenType: 'Bearer',
        expiresIn: 900,
      );
      const m2 = AuthTokensModel(
        accessToken: 'a',
        refreshToken: 'r',
        tokenType: 'Bearer',
        expiresIn: 900,
      );
      const m3 = AuthTokensModel(
        accessToken: 'b',
        refreshToken: 'r',
        tokenType: 'Bearer',
        expiresIn: 900,
      );

      expect(m1, equals(m2));
      expect(m1, isNot(equals(m3)));
    });
  });
}
