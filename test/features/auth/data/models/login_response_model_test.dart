import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/auth/data/models/login_response_model.dart';

void main() {
  group('LoginResponseModel Tests', () {
    final tJson = {
      'user': {
        'id': 'usr_123',
        'email': 'admin@kawalo.id',
        'name': 'Admin Kawalo',
        'avatar_url': null,
        'active_group': null,
        'groups': <Map<String, dynamic>>[],
      },
      'tokens': {
        'access_token': 'jwt_access',
        'refresh_token': 'opaque_refresh',
        'token_type': 'Bearer',
        'expires_in': 900,
      },
    };

    test(
      'fromJson parses user and tokens correctly according to DTO schema',
      () {
        final model = LoginResponseModel.fromJson(tJson);

        expect(model.user.id, equals('usr_123'));
        expect(model.user.email, equals('admin@kawalo.id'));
        expect(model.tokens.accessToken, equals('jwt_access'));
        expect(model.tokens.tokenType, equals('Bearer'));
        expect(model.tokens.expiresIn, equals(900));
        expect(model.props, equals([model.user, model.tokens]));
      },
    );
  });
}
