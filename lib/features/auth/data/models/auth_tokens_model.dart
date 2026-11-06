import 'package:equatable/equatable.dart';

/// Model serialisasi token autentikasi (JWT Access Token & Refresh Token)
/// (`TokensResponseDto`).
///
/// Merupakan Pure DTO tanpa mengimpor domain entity, tanpa logika bisnis,
/// tanpa fallback dummy, dan tanpa sanitasi data.
class AuthTokensModel extends Equatable {
  /// Membuat instance [AuthTokensModel].
  const AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  /// Mengonversi payload map JSON menjadi [AuthTokensModel] tanpa fallback
  /// dummy dan tanpa sanitasi data.
  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String,
      expiresIn: json['expires_in'] as int,
    );
  }

  /// Token akses (JWT).
  final String accessToken;

  /// Token penyegaran sesi.
  final String refreshToken;

  /// Tipe token (misal: "Bearer").
  final String tokenType;

  /// Masa berlaku dalam detik.
  final int expiresIn;

  @override
  List<Object?> get props => [accessToken, refreshToken, tokenType, expiresIn];
}
