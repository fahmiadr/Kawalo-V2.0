import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'switch_group_request_model.g.dart';

/// Model request keluar (outbound DTO) untuk berganti grup aktif
/// (`SwitchGroupDto`, `POST /v1/auth/switch-group`).
@JsonSerializable(fieldRename: FieldRename.snake)
class SwitchGroupRequestModel extends Equatable {
  const SwitchGroupRequestModel({required this.groupUid});

  /// Target Group UID yang akan diaktifkan.
  final String groupUid;

  Map<String, dynamic> toJson() => _$SwitchGroupRequestModelToJson(this);

  @override
  List<Object?> get props => [groupUid];
}
