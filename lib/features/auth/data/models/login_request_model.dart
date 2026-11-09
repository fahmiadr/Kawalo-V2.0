import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'login_request_model.g.dart';

/// Model request keluar (outbound DTO) untuk proses login pengguna
/// (`LoginDto`, `POST /v1/auth/login`).
@JsonSerializable(fieldRename: FieldRename.snake)
class LoginRequestModel extends Equatable {
  const LoginRequestModel({
    required this.email,
    required this.password,
    this.groupUid,
  });

  final String email;
  final String password;

  /// UID grup aktif pilihan (opsional).
  final String? groupUid;

  /// A null or empty `group_uid` is dropped before it reaches the backend.
  Map<String, dynamic> toJson() => _$LoginRequestModelToJson(this)
    ..removeWhere(
      (key, value) => key == 'group_uid' && (value == null || value == ''),
    );

  @override
  List<Object?> get props => [email, password, groupUid];
}
