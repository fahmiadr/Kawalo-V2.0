import 'package:equatable/equatable.dart';

/// Model request keluar (outbound DTO) untuk memperbarui sesi token
/// (`RefreshTokenDto`).
///
/// Merupakan Outbound Pure DTO yang hanya memiliki serialisasi ke luar
/// ([toJson]) dan tidak memiliki deserialisasi `fromJson`.
class RefreshTokenRequestModel extends Equatable {
  /// Membuat instance [RefreshTokenRequestModel].
  const RefreshTokenRequestModel({
    required this.refreshToken,
  });

  /// Raw refresh token (64 karakter hex string).
  final String refreshToken;

  /// Mengonversi payload menjadi representasi JSON outbound untuk dikirim ke
  /// backend API (`POST /v1/auth/refresh`).
  Map<String, dynamic> toJson() {
    return {
      'refresh_token': refreshToken,
    };
  }

  @override
  List<Object?> get props => [refreshToken];
}
