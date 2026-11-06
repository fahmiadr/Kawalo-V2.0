import 'package:equatable/equatable.dart';

/// Model data grup kawasan pengguna untuk pertukaran JSON dengan backend
/// (`UserGroupAccessDto`).
///
/// Merupakan Pure DTO tanpa mengimpor atau mewarisi domain entity, tanpa
/// fallback dummy, mengikuti spesifikasi kontrak backend.
class UserGroupModel extends Equatable {
  /// Membuat instance [UserGroupModel].
  const UserGroupModel({
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

  /// Mengonversi payload map JSON menjadi [UserGroupModel] tanpa fallback
  /// dummy dan tanpa sanitasi data.
  factory UserGroupModel.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'] as List<dynamic>;

    return UserGroupModel(
      groupUid: json['group_uid'] as String,
      groupName: json['group_name'] as String?,
      groupOwner: json['group_owner'] as String?,
      groupLogo: json['group_logo'] as String?,
      groupStatus: json['group_status'] as String?,
      category: json['category'] as String?,
      status: json['status'] as String?,
      allowAdmin: json['allow_admin'] as bool,
      allowPatrol: json['allow_patrol'] as bool,
      allowMonPatrol: json['allow_mon_patrol'] as bool,
      features: rawFeatures.cast<String>().toList(growable: false),
    );
  }

  /// UID unik grup.
  final String groupUid;

  /// Nama grup kawasan.
  final String? groupName;

  /// Pemilik grup.
  final String? groupOwner;

  /// Kategori grup (role pengguna di grup, e.g. "ADMIN", "GUARD").
  final String? category;

  /// Status keanggotaan pengguna di grup (e.g. "JOINED", "PENDING").
  final String? status;

  /// Status langganan grup (e.g. "CLIENT", "TRIAL").
  final String? groupStatus;

  /// URL logo grup.
  final String? groupLogo;

  /// Izin administratif.
  final bool allowAdmin;

  /// Izin patroli.
  final bool allowPatrol;

  /// Izin monitor patroli.
  final bool allowMonPatrol;

  /// Fitur-fitur aktif grup.
  final List<String> features;

  /// Mengonversi objek menjadi representasi map JSON.
  Map<String, dynamic> toJson() {
    return {
      'group_uid': groupUid,
      'group_name': groupName,
      'group_owner': groupOwner,
      'category': category,
      'status': status,
      'group_status': groupStatus,
      'group_logo': groupLogo,
      'allow_admin': allowAdmin,
      'allow_patrol': allowPatrol,
      'allow_mon_patrol': allowMonPatrol,
      'features': features,
    };
  }

  @override
  List<Object?> get props => [
        groupUid,
        groupName,
        groupOwner,
        category,
        status,
        groupStatus,
        groupLogo,
        allowAdmin,
        allowPatrol,
        allowMonPatrol,
        features,
      ];
}

/// Model data profil pengguna untuk pertukaran JSON dengan backend
/// (`SafeUserDto`).
///
/// Merupakan Pure DTO tanpa mengimpor atau mewarisi domain entity, tanpa
/// fallback dummy, mengikuti spesifikasi kontrak backend.
class UserModel extends Equatable {
  /// Membuat instance [UserModel].
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.groups,
    this.avatarUrl,
    this.activeGroup,
  });

  /// Mengonversi payload map JSON menjadi [UserModel] murni sesuai
  /// SafeUserDto.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final activeGroupJson = json['active_group'] as Map<String, dynamic>?;
    final groupsJson = json['groups'] as List<dynamic>;

    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      activeGroup: activeGroupJson != null
          ? UserGroupModel.fromJson(activeGroupJson)
          : null,
      groups: groupsJson
          .map((e) => UserGroupModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  /// ID unik pengguna.
  final String id;

  /// Alamat email pengguna.
  final String email;

  /// Nama lengkap pengguna.
  final String name;

  /// URL avatar pengguna.
  final String? avatarUrl;

  /// Grup aktif pengguna saat ini.
  final UserGroupModel? activeGroup;

  /// Daftar semua grup yang diikuti pengguna.
  final List<UserGroupModel> groups;

  /// Mengonversi objek menjadi representasi map JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'active_group': activeGroup?.toJson(),
      'groups': groups.map((g) => g.toJson()).toList(),
    };
  }

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
