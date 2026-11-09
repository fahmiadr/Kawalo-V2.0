import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

/// Model data grup kawasan pengguna untuk pertukaran JSON dengan backend
/// (`UserGroupAccessDto`).
@JsonSerializable(fieldRename: FieldRename.snake, checked: true)
class UserGroupModel extends Equatable {
  const UserGroupModel({
    required this.groupUid,
    required this.allowAdmin,
    required this.allowPatrol,
    required this.allowMonPatrol,
    required this.features,
    this.groupName,
    this.groupOwner,
    this.groupLogo,
    this.groupStatus,
    this.category,
    this.status,
  });

  factory UserGroupModel.fromJson(Map<String, dynamic> json) =>
      _$UserGroupModelFromJson(json);

  final String groupUid;
  final String? groupName;
  final String? groupOwner;

  /// Kategori grup (role pengguna di grup, e.g. "ADMIN", "GUARD").
  final String? category;

  /// Status keanggotaan pengguna di grup (e.g. "JOINED", "PENDING").
  final String? status;

  /// Status langganan grup (e.g. "CLIENT", "TRIAL").
  final String? groupStatus;

  final String? groupLogo;

  // Missing permission flags default to false: denying access is the safe side.
  @JsonKey(defaultValue: false)
  final bool allowAdmin;

  @JsonKey(defaultValue: false)
  final bool allowPatrol;

  @JsonKey(defaultValue: false)
  final bool allowMonPatrol;

  /// Fitur-fitur aktif grup.
  @JsonKey(defaultValue: <String>[])
  final List<String> features;

  Map<String, dynamic> toJson() => _$UserGroupModelToJson(this);

  @override
  List<Object?> get props => [
        groupUid,
        groupName,
        groupOwner,
        category,
        status,
        groupStatus,
        groupLogo,
        allowAdmin,
        allowPatrol,
        allowMonPatrol,
        features,
      ];
}

/// Model data profil pengguna untuk pertukaran JSON dengan backend
/// (`SafeUserDto`).
@JsonSerializable(
  fieldRename: FieldRename.snake,
  explicitToJson: true,
  checked: true,
)
class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.groups,
    this.avatarUrl,
    this.activeGroup,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  final String id;
  final String email;
  final String name;
  final String? avatarUrl;

  /// Grup aktif pengguna saat ini.
  final UserGroupModel? activeGroup;

  /// Daftar semua grup yang diikuti pengguna.
  final List<UserGroupModel> groups;

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        avatarUrl,
        activeGroup,
        groups,
      ];
}
