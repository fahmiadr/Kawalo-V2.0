// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupMemberModel _$GroupMemberModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GroupMemberModel', json, ($checkedConvert) {
      final val = GroupMemberModel(
        email: $checkedConvert('email', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String?),
        profilePic: $checkedConvert('profilePic', (v) => v as String?),
      );
      return val;
    });
