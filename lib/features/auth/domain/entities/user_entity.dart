import 'package:equatable/equatable.dart';

/// Entitas bisnis domain yang merepresentasikan data akses grup pengguna.
class UserGroupEntity extends Equatable {
  /// Membuat instance [UserGroupEntity].
  const UserGroupEntity({
    required this.groupUid,
    required this.allowAdmin,
    required this.allowPatrol,
    required this.allowMonPatrol,
    required this.features,
    this.groupName,
    this.groupOwner,
    this.groupLogo,
    this.groupStatus,
    this.category,
    this.status,
  });

  /// UID unik grup kawasan.
  final String groupUid;

  /// Izin administratif.
  final bool allowAdmin;

  /// Izin patroli.
  final bool allowPatrol;

  /// Izin monitor patroli.
  final bool allowMonPatrol;

  /// Fitur-fitur aktif grup.
  final List<String> features;

  /// Nama grup kawasan.
  final String? groupName;

  /// Pemilik grup.
  final String? groupOwner;

  /// URL logo grup.
  final String? groupLogo;

  /// Status langganan grup (e.g. CLIENT, TRIAL).
  final String? groupStatus;

  /// Kategori / role pengguna di grup (e.g. ADMIN, GUARD).
  final String? category;

  /// Status keanggotaan pengguna di grup (e.g. JOINED, PENDING).
  final String? status;

  @override
  List<Object?> get props => [
        groupUid,
        allowAdmin,
        allowPatrol,
        allowMonPatrol,
        features,
        groupName,
        groupOwner,
        groupLogo,
        groupStatus,
        category,
        status,
      ];
}

/// Entitas bisnis domain yang merepresentasikan pengguna terautentikasi.
class UserEntity extends Equatable {
  /// Membuat instance [UserEntity].
  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.groups,
    this.avatarUrl,
    this.activeGroup,
  });

  /// ID unik pengguna.
  final String id;

  /// Alamat email pengguna.
  final String email;

  /// Nama lengkap pengguna.
  final String name;

  /// URL avatar pengguna.
  final String? avatarUrl;

  /// Grup aktif pengguna saat ini.
  final UserGroupEntity? activeGroup;

  /// Daftar semua grup kawasan yang diikuti pengguna.
  final List<UserGroupEntity> groups;

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        avatarUrl,
        activeGroup,
        groups,
      ];
}
