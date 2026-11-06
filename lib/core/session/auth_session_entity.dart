import 'package:equatable/equatable.dart';

/// Entitas inti (Shared Kernel) yang merepresentasikan sesi autentikasi
/// pengguna berdasarkan klaim JWT Access Token yang terverifikasi secara
/// kriptografis.
class AuthSessionEntity extends Equatable {
  /// Membuat instance [AuthSessionEntity].
  const AuthSessionEntity({
    required this.userId,
    required this.email,
    required this.name,
    required this.allowAdmin,
    required this.allowPatrol,
    required this.allowMonPatrol,
    this.role,
    this.groupUid,
  });

  /// ID pengguna (klaim `sub` pada JWT).
  final String userId;

  /// Alamat email resmi pengguna.
  final String email;

  /// Nama lengkap pengguna.
  final String name;

  /// Role aktif pengguna pada sesi ini (misal: 'ADMIN', 'GUARD').
  final String? role;

  /// UID grup aktif yang sedang digunakan pada sesi ini.
  final String? groupUid;

  /// Izin akses administratif.
  final bool allowAdmin;

  /// Izin pelaksanaan kegiatan patroli.
  final bool allowPatrol;

  /// Izin monitoring pelaksanaan patroli.
  final bool allowMonPatrol;

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
