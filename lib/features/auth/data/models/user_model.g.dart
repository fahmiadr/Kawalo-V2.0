// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserGroupModel _$UserGroupModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'UserGroupModel',
  json,
  ($checkedConvert) {
    final val = UserGroupModel(
      groupUid: $checkedConvert('group_uid', (v) => v as String),
      allowAdmin: $checkedConvert('allow_admin', (v) => v as bool? ?? false),
      allowPatrol: $checkedConvert('allow_patrol', (v) => v as bool? ?? false),
      allowMonPatrol: $checkedConvert(
        'allow_mon_patrol',
        (v) => v as bool? ?? false,
      ),
      features: $checkedConvert(
        'features',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      ),
      groupName: $checkedConvert('group_name', (v) => v as String?),
      groupOwner: $checkedConvert('group_owner', (v) => v as String?),
      groupLogo: $checkedConvert('group_logo', (v) => v as String?),
      groupStatus: $checkedConvert('group_status', (v) => v as String?),
      category: $checkedConvert('category', (v) => v as String?),
      status: $checkedConvert('status', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'groupUid': 'group_uid',
    'allowAdmin': 'allow_admin',
    'allowPatrol': 'allow_patrol',
    'allowMonPatrol': 'allow_mon_patrol',
    'groupName': 'group_name',
    'groupOwner': 'group_owner',
    'groupLogo': 'group_logo',
    'groupStatus': 'group_status',
  },
);

Map<String, dynamic> _$UserGroupModelToJson(UserGroupModel instance) =>
    <String, dynamic>{
      'group_uid': instance.groupUid,
      'group_name': instance.groupName,
      'group_owner': instance.groupOwner,
      'category': instance.category,
      'status': instance.status,
      'group_status': instance.groupStatus,
      'group_logo': instance.groupLogo,
      'allow_admin': instance.allowAdmin,
      'allow_patrol': instance.allowPatrol,
      'allow_mon_patrol': instance.allowMonPatrol,
      'features': instance.features,
    };

UserModel _$UserModelFromJson(Map<String, dynamic> json) => $checkedCreate(
  'UserModel',
  json,
  ($checkedConvert) {
    final val = UserModel(
      id: $checkedConvert('id', (v) => v as String),
      email: $checkedConvert('email', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      groups: $checkedConvert(
        'groups',
        (v) => (v as List<dynamic>)
            .map((e) => UserGroupModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      avatarUrl: $checkedConvert('avatar_url', (v) => v as String?),
      activeGroup: $checkedConvert(
        'active_group',
        (v) => v == null
            ? null
            : UserGroupModel.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'avatarUrl': 'avatar_url', 'activeGroup': 'active_group'},
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'name': instance.name,
  'avatar_url': instance.avatarUrl,
  'active_group': instance.activeGroup?.toJson(),
  'groups': instance.groups.map((e) => e.toJson()).toList(),
};
