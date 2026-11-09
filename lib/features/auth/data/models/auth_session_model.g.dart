// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthSessionModel _$AuthSessionModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'AuthSessionModel',
  json,
  ($checkedConvert) {
    final val = AuthSessionModel(
      userId: $checkedConvert('user_id', (v) => v as String),
      email: $checkedConvert('email', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      allowAdmin: $checkedConvert('allow_admin', (v) => v as bool? ?? false),
      allowPatrol: $checkedConvert('allow_patrol', (v) => v as bool? ?? false),
      allowMonPatrol: $checkedConvert(
        'allow_mon_patrol',
        (v) => v as bool? ?? false,
      ),
      role: $checkedConvert('role', (v) => v as String?),
      groupUid: $checkedConvert('group_uid', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'userId': 'user_id',
    'allowAdmin': 'allow_admin',
    'allowPatrol': 'allow_patrol',
    'allowMonPatrol': 'allow_mon_patrol',
    'groupUid': 'group_uid',
  },
);

Map<String, dynamic> _$AuthSessionModelToJson(AuthSessionModel instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'email': instance.email,
      'name': instance.name,
      'role': instance.role,
      'group_uid': instance.groupUid,
      'allow_admin': instance.allowAdmin,
      'allow_patrol': instance.allowPatrol,
      'allow_mon_patrol': instance.allowMonPatrol,
    };
