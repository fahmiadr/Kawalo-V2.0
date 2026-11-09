import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:kawalo_mobile/core/network/json_converters.dart';

part 'auth_tokens_model.g.dart';

/// Model serialisasi token autentikasi (JWT Access Token & Refresh Token)
/// (`TokensResponseDto`).
@JsonSerializable(
  fieldRename: FieldRename.snake,
  createToJson: false,
  checked: true,
)
class AuthTokensModel extends Equatable {
  const AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensModelFromJson(json);

  final String accessToken;
  final String refreshToken;

  /// Tipe token (misal: "Bearer").
  final String tokenType;

  /// Masa berlaku dalam detik.
  @IntFromNumConverter()
  final int expiresIn;

  @override
  List<Object?> get props => [accessToken, refreshToken, tokenType, expiresIn];
}
