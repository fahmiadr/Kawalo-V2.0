import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'logout_request_model.g.dart';

/// Model request keluar (outbound DTO) untuk proses logout pengguna
/// (`LogoutDto`, `POST /v1/auth/logout`).
@JsonSerializable(fieldRename: FieldRename.snake)
class LogoutRequestModel extends Equatable {
  const LogoutRequestModel({this.refreshToken});

  /// Refresh token yang akan dicabut (opsional).
  final String? refreshToken;

  /// A null or empty `refresh_token` is dropped before it reaches the
  /// backend.
  Map<String, dynamic> toJson() => _$LogoutRequestModelToJson(this)
    ..removeWhere(
      (key, value) => key == 'refresh_token' && (value == null || value == ''),
    );

  @override
  List<Object?> get props => [refreshToken];
}
