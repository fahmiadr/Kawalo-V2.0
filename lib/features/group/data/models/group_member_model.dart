import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_member_model.g.dart';

/// Pure DTO model untuk representasi JSON data anggota grup dari API.
@JsonSerializable(createToJson: false, checked: true)
class GroupMemberModel extends Equatable {
  const GroupMemberModel({required this.email, this.name, this.profilePic});

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberModelFromJson(json);

  final String email;
  final String? name;
  final String? profilePic;

  @override
  List<Object?> get props => [email, name, profilePic];
}
