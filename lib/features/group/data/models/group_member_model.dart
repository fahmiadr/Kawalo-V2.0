import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_member_model.g.dart';

/// Pure DTO model untuk representasi JSON data anggota grup dari API.
@JsonSerializable(createToJson: false, checked: true)
class GroupMemberModel extends Equatable {
  const GroupMemberModel({
    required this.email,
    this.name,
    this.profilePic,
    this.avatarUrl,
    this.role,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberModelFromJson(json);

  final String email;
  final String? name;
  final String? profilePic;

  /// Newer key for the same photo; preferred over [profilePic].
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  /// Category of the member in the active group (`ADMIN`, `GUARD`, `USER`);
  /// absent from older servers.
  final String? role;

  @override
  List<Object?> get props => [email, name, profilePic, avatarUrl, role];
}
