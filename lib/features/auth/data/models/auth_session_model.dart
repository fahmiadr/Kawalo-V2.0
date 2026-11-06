import 'package:equatable/equatable.dart';

/// Model DTO untuk serialisasi sesi autentikasi pengguna dari klaim JWT
/// atau penyimpanan lokal aman (Secure Storage).
class AuthSessionModel extends Equatable {
  /// Membuat instance [AuthSessionModel].
  const AuthSessionModel({
    required this.userId,
    required this.email,
    required this.name,
    required this.allowAdmin,
    required this.allowPatrol,
    required this.allowMonPatrol,
    this.role,
    this.groupUid,
  });

  /// Mengonversi payload map JWT yang terverifikasi menjadi [AuthSessionModel]
  /// tanpa fallback dummy dan tanpa sanitasi data.
  factory AuthSessionModel.fromJwtPayload(Map<String, dynamic> payload) {
    return AuthSessionModel(
      userId: payload['sub'] as String,
      email: payload['email'] as String,
      name: payload['name'] as String,
      role: payload['role'] as String?,
      groupUid: payload['group_uid'] as String?,
      allowAdmin: payload['allow_admin'] as bool,
      allowPatrol: payload['allow_patrol'] as bool,
      allowMonPatrol: payload['allow_mon_patrol'] as bool,
    );
  }

  /// Mengonversi JSON map dari secure storage menjadi [AuthSessionModel].
  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      userId: json['user_id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String?,
      groupUid: json['group_uid'] as String?,
      allowAdmin: json['allow_admin'] as bool,
      allowPatrol: json['allow_patrol'] as bool,
      allowMonPatrol: json['allow_mon_patrol'] as bool,
    );
  }

  /// ID unik pengguna (`sub`).
  final String userId;

  /// Alamat email pengguna.
  final String email;

  /// Nama lengkap pengguna.
  final String name;

  /// Role aktif pengguna pada grup saat ini.
  final String? role;

  /// UID grup aktif sesi saat ini.
  final String? groupUid;

  /// Izin akses panel admin.
  final bool allowAdmin;

  /// Izin akses fitur patroli lapangan.
  final bool allowPatrol;

  /// Izin akses fitur monitoring patroli.
  final bool allowMonPatrol;

  /// Mengonversi model ke JSON map untuk disimpan di Secure Storage.
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'email': email,
        'name': name,
        'role': role,
        'group_uid': groupUid,
        'allow_admin': allowAdmin,
        'allow_patrol': allowPatrol,
        'allow_mon_patrol': allowMonPatrol,
      };

  @override
  List<Object?> get props => [
        userId,
        email,
        name,
        role,
        groupUid,
        allowAdmin,
        allowPatrol,
        allowMonPatrol,
      ];
}
