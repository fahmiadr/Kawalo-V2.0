import 'package:json_annotation/json_annotation.dart';

part 'ptt_member_model.g.dart';

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class PttMemberModel {
  const PttMemberModel({
    required this.userId,
    required this.name,
    required this.role,
    this.speaking = false,
  });

  factory PttMemberModel.fromJson(Map<String, dynamic> json) =>
      _$PttMemberModelFromJson(json);

  @JsonKey(defaultValue: '')
  final String userId;

  @JsonKey(defaultValue: '')
  final String name;

  @JsonKey(defaultValue: '')
  final String role;

  @JsonKey(defaultValue: false)
  final bool speaking;
}
