import 'package:equatable/equatable.dart';

/// Entitas bisnis domain yang merepresentasikan token autentikasi sesi.
class AuthTokensEntity extends Equatable {
  /// Membuat instance [AuthTokensEntity].
  const AuthTokensEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  /// Token akses (JWT).
  final String accessToken;

  /// Token penyegaran sesi.
  final String refreshToken;

  /// Tipe token otentikasi (misal: "Bearer").
  final String tokenType;

  /// Masa kedaluwarsa token dalam detik.
  final int expiresIn;

  @override
  List<Object?> get props => [accessToken, refreshToken, tokenType, expiresIn];
}
