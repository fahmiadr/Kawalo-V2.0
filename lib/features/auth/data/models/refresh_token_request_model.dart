import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'refresh_token_request_model.g.dart';

/// Model request keluar (outbound DTO) untuk memperbarui sesi token
/// (`RefreshTokenDto`, `POST /v1/auth/refresh`).
@JsonSerializable(fieldRename: FieldRename.snake)
class RefreshTokenRequestModel extends Equatable {
  const RefreshTokenRequestModel({required this.refreshToken});

  /// Raw refresh token (64 karakter hex string).
  final String refreshToken;

  Map<String, dynamic> toJson() => _$RefreshTokenRequestModelToJson(this);

  @override
  List<Object?> get props => [refreshToken];
}
