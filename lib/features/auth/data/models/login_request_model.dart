import 'package:equatable/equatable.dart';

/// Model request keluar (outbound DTO) untuk proses login pengguna
/// (`LoginDto`).
///
/// Merupakan Outbound Pure DTO yang hanya memiliki serialisasi ke luar
/// ([toJson]) dan tidak memiliki deserialisasi `fromJson`.
class LoginRequestModel extends Equatable {
  /// Membuat instance [LoginRequestModel].
  const LoginRequestModel({
    required this.email,
    required this.password,
    this.groupUid,
  });

  /// Alamat email personil Kawalo.
  final String email;

  /// Kata sandi personil.
  final String password;

  /// UID grup aktif pilihan (opsional).
  final String? groupUid;

  /// Mengonversi payload menjadi representasi JSON outbound untuk dikirim ke
  /// backend API (`POST /v1/auth/login`).
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      if (groupUid != null && groupUid!.isNotEmpty) 'group_uid': groupUid,
    };
  }

  @override
  List<Object?> get props => [email, password, groupUid];
}
