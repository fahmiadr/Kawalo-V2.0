import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/auth/data/models/auth_tokens_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/user_model.dart';

/// Model respons login untuk pertukaran JSON dengan backend
/// (`LoginResponseDto`).
///
/// Merupakan Pure DTO tanpa mengimpor atau mewarisi domain entity, tanpa
/// fallback dummy, mengikuti spesifikasi kontrak backend.
class LoginResponseModel extends Equatable {
  /// Membuat instance [LoginResponseModel].
  const LoginResponseModel({
    required this.user,
    required this.tokens,
  });

  /// Mengonversi payload map JSON menjadi [LoginResponseModel] murni sesuai
  /// LoginResponseDto.
  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      tokens: AuthTokensModel.fromJson(json['tokens'] as Map<String, dynamic>),
    );
  }

  /// Profil data pengguna.
  final UserModel user;

  /// Sepasang token akses dan token refresh.
  final AuthTokensModel tokens;

  @override
  List<Object?> get props => [user, tokens];
}
