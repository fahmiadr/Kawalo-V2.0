import 'package:equatable/equatable.dart';

/// Model request keluar (outbound DTO) untuk proses logout pengguna
/// (`LogoutDto`).
///
/// Merupakan Outbound Pure DTO yang hanya memiliki serialisasi ke luar
/// ([toJson]) dan tidak memiliki deserialisasi `fromJson`.
class LogoutRequestModel extends Equatable {
  /// Membuat instance [LogoutRequestModel].
  const LogoutRequestModel({
    this.refreshToken,
  });

  /// Refresh token yang akan dicabut (opsional).
  final String? refreshToken;

  /// Mengonversi payload menjadi representasi JSON outbound untuk dikirim ke
  /// backend API (`POST /v1/auth/logout`).
  Map<String, dynamic> toJson() {
    return {
      if (refreshToken != null && refreshToken!.isNotEmpty)
        'refresh_token': refreshToken,
    };
  }

  @override
  List<Object?> get props => [refreshToken];
}
