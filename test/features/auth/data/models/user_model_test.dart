import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel & UserGroupModel Tests', () {
    const tGroupJson = {
      'group_uid': 'grp_123',
      'group_name': 'Cluster Alpha',
      'group_owner': 'Owner PT',
      'category': 'GUARD',
      'status': 'JOINED',
      'group_status': 'CLIENT',
      'group_logo': 'alpha_logo.png',
      'allow_admin': false,
      'allow_patrol': true,
      'allow_mon_patrol': false,
      'features': ['PATROL'],
    };

    final tUserJson = {
      'id': '101',
      'email': 'personil@kawalo.co.id',
      'name': 'Personil Lapangan',
      'avatar_url': 'avatar.jpg',
      'active_group': tGroupJson,
      'groups': [tGroupJson],
    };

    test(
      'fromJson memetakan profil dan active_group murni sesuai SafeUserDto',
      () {
        final user = UserModel.fromJson(tUserJson);

        expect(user.id, '101');
        expect(user.email, 'personil@kawalo.co.id');
        expect(user.name, 'Personil Lapangan');
        expect(user.avatarUrl, 'avatar.jpg');
        expect(user.activeGroup?.category, 'GUARD');
        expect(user.activeGroup?.status, 'JOINED');
        expect(user.activeGroup?.allowAdmin, false);
        expect(user.activeGroup?.allowPatrol, true);
        expect(user.activeGroup?.allowMonPatrol, false);
        expect(user.groups, hasLength(1));
      },
    );

    test(
      'toJson harus menyertakan data grup dan user tanpa privileges, role, '
      'atau redundansi allow_* di root',
      () {
        final user = UserModel.fromJson(tUserJson);
        final json = user.toJson();

        expect(json['id'], '101');
        expect(json.containsKey('role'), false);
        expect(json.containsKey('allow_admin'), false);
        expect(json.containsKey('allow_patrol'), false);
        expect(json.containsKey('allow_mon_patrol'), false);

        final activeGroupJson = json['active_group'] as Map<String, dynamic>;
        expect(activeGroupJson['category'], 'GUARD');
        expect(activeGroupJson['status'], 'JOINED');
        expect(activeGroupJson['allow_admin'], false);
        expect(activeGroupJson['allow_patrol'], true);
        expect(activeGroupJson['allow_mon_patrol'], false);
        expect(activeGroupJson.containsKey('role'), false);
        expect(activeGroupJson.containsKey('privileges'), false);
      },
    );

    test(
      'UserGroupModel.fromJson memetakan payload snake_case resmi tanpa '
      'alias role dan tanpa privileges',
      () {
        final groupJson = {
          'group_uid': 'grp_456',
          'group_name': 'Cluster Beta',
          'category': 'ADMIN',
          'status': 'JOINED',
          'allow_admin': true,
          'allow_patrol': true,
          'allow_mon_patrol': true,
          'features': ['ADMIN_PANEL'],
        };

        final group = UserGroupModel.fromJson(groupJson);
        expect(group.groupUid, 'grp_456');
        expect(group.category, 'ADMIN');
        expect(group.allowAdmin, true);
        expect(group.allowPatrol, true);
        expect(group.allowMonPatrol, true);
        expect(group.features, ['ADMIN_PANEL']);
      },
    );
  });
}
