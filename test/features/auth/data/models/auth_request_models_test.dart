import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/auth/data/models/login_request_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/logout_request_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/refresh_token_request_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/switch_group_request_model.dart';

void main() {
  group('Auth Outbound Request Models Tests', () {
    test('LoginRequestModel.toJson serializes correctly with groupUid', () {
      const model = LoginRequestModel(
        email: 'personil@kawalo.id',
        password: 'secretPassword',
        groupUid: 'grp_001',
      );

      final json = model.toJson();
      expect(json['email'], 'personil@kawalo.id');
      expect(json['password'], 'secretPassword');
      expect(json['group_uid'], 'grp_001');
    });

    test('LoginRequestModel.toJson omits groupUid when null or empty', () {
      const model = LoginRequestModel(
        email: 'personil@kawalo.id',
        password: 'secretPassword',
      );

      final json = model.toJson();
      expect(json['email'], 'personil@kawalo.id');
      expect(json['password'], 'secretPassword');
      expect(json.containsKey('group_uid'), isFalse);

      const emptyGroupModel = LoginRequestModel(
        email: 'personil@kawalo.id',
        password: 'secretPassword',
        groupUid: '',
      );
      expect(emptyGroupModel.toJson().containsKey('group_uid'), isFalse);
    });

    test('RefreshTokenRequestModel.toJson serializes refresh_token', () {
      final model = RefreshTokenRequestModel(
        refreshToken: 'a' * 64,
      );

      final json = model.toJson();
      expect(json['refresh_token'], 'a' * 64);
    });

    test('SwitchGroupRequestModel.toJson serializes group_uid', () {
      const model = SwitchGroupRequestModel(
        groupUid: 'grp_target_99',
      );

      final json = model.toJson();
      expect(json['group_uid'], 'grp_target_99');
    });

    test('LogoutRequestModel.toJson serializes optional refresh_token', () {
      const modelWithToken = LogoutRequestModel(
        refreshToken: 'token_to_revoke',
      );
      expect(modelWithToken.toJson()['refresh_token'], 'token_to_revoke');

      const modelWithoutToken = LogoutRequestModel();
      expect(modelWithoutToken.toJson().containsKey('refresh_token'), isFalse);

      const modelWithEmptyToken = LogoutRequestModel(refreshToken: '');
      expect(
        modelWithEmptyToken.toJson().containsKey('refresh_token'),
        isFalse,
      );
    });

    test('Props equality compares outbound models by value', () {
      const login1 = LoginRequestModel(email: 'a@b.c', password: '123');
      const login2 = LoginRequestModel(email: 'a@b.c', password: '123');
      const login3 = LoginRequestModel(email: 'x@b.c', password: '123');
      expect(login1, equals(login2));
      expect(login1, isNot(equals(login3)));

      const refresh1 = RefreshTokenRequestModel(refreshToken: 'tok1');
      const refresh2 = RefreshTokenRequestModel(refreshToken: 'tok1');
      expect(refresh1, equals(refresh2));

      const switch1 = SwitchGroupRequestModel(groupUid: 'grp1');
      const switch2 = SwitchGroupRequestModel(groupUid: 'grp1');
      expect(switch1, equals(switch2));

      const logout1 = LogoutRequestModel(refreshToken: 'tok1');
      const logout2 = LogoutRequestModel(refreshToken: 'tok1');
      expect(logout1, equals(logout2));
    });
  });
}
