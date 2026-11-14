// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ptt_member_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PttMemberModel _$PttMemberModelFromJson(Map<String, dynamic> json) =>
    PttMemberModel(
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      speaking: json['speaking'] as bool? ?? false,
    );
