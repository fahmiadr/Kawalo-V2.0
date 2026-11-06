import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/utils/app_sanitizer.dart';
import 'package:kawalo_mobile/features/auth/data/models/auth_session_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/auth_tokens_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/user_model.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/auth_tokens_entity.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';

/// Mapper dua arah untuk konversi DTO <-> Domain Entity pada modul autentikasi.
///
/// Menerapkan pola Dedicated Mapper dengan Anti-Corruption Layer (ACL)
/// menggunakan [AppSanitizer] tanpa fallback dummy.
abstract final class AuthMapper {
  const AuthMapper._();

  /// Mengonversi [AuthTokensModel] DTO menjadi [AuthTokensEntity] Domain dengan
  /// sanitasi data.
  static AuthTokensEntity toTokensEntity(AuthTokensModel model) {
    return AuthTokensEntity(
      accessToken: AppSanitizer.cleanString(model.accessToken) ??
          model.accessToken.trim(),
      refreshToken: AppSanitizer.cleanString(model.refreshToken) ??
          model.refreshToken.trim(),
      tokenType:
          AppSanitizer.cleanString(model.tokenType) ?? model.tokenType.trim(),
      expiresIn: AppSanitizer.cleanInteger(model.expiresIn) ?? model.expiresIn,
    );
  }

  /// Mengonversi [AuthTokensEntity] Domain menjadi [AuthTokensModel] DTO.
  static AuthTokensModel toTokensModel(AuthTokensEntity entity) {
    return AuthTokensModel(
      accessToken: entity.accessToken,
      refreshToken: entity.refreshToken,
      tokenType: entity.tokenType,
      expiresIn: entity.expiresIn,
    );
  }

  /// Mengonversi [UserGroupModel] DTO menjadi [UserGroupEntity] Domain dengan
  /// sanitasi data.
  static UserGroupEntity toUserGroupEntity(UserGroupModel model) {
    return UserGroupEntity(
      groupUid:
          AppSanitizer.cleanString(model.groupUid) ?? model.groupUid.trim(),
      groupName: AppSanitizer.cleanString(model.groupName),
      groupOwner: AppSanitizer.cleanString(model.groupOwner),
      category: AppSanitizer.cleanRole(model.category),
      status: AppSanitizer.cleanString(model.status),
      groupStatus: AppSanitizer.cleanString(model.groupStatus),
      groupLogo: AppSanitizer.cleanString(model.groupLogo),
      allowAdmin: model.allowAdmin,
      allowPatrol: model.allowPatrol,
      allowMonPatrol: model.allowMonPatrol,
      features: AppSanitizer.cleanStringList(model.features),
    );
  }

  /// Mengonversi [UserGroupEntity] Domain menjadi [UserGroupModel] DTO.
  static UserGroupModel toUserGroupModel(UserGroupEntity entity) {
    return UserGroupModel(
      groupUid: entity.groupUid,
      groupName: entity.groupName,
      groupOwner: entity.groupOwner,
      category: entity.category,
      status: entity.status,
      groupStatus: entity.groupStatus,
      groupLogo: entity.groupLogo,
      allowAdmin: entity.allowAdmin,
      allowPatrol: entity.allowPatrol,
      allowMonPatrol: entity.allowMonPatrol,
      features: entity.features,
    );
  }

  /// Mengonversi [UserModel] DTO menjadi [UserEntity] Domain dengan
  /// normalisasi email dan sanitasi via [AppSanitizer].
  static UserEntity toUserEntity(UserModel model) {
    return UserEntity(
      id: AppSanitizer.cleanString(model.id) ?? model.id.trim(),
      email: AppSanitizer.cleanEmail(model.email) ??
          model.email.trim().toLowerCase(),
      name: AppSanitizer.cleanString(model.name) ?? model.name.trim(),
      groups: model.groups.map(toUserGroupEntity).toList(growable: false),
      avatarUrl: AppSanitizer.cleanString(model.avatarUrl),
      activeGroup: model.activeGroup != null
          ? toUserGroupEntity(model.activeGroup!)
          : null,
    );
  }

  /// Mengonversi [UserEntity] Domain menjadi [UserModel] DTO.
  static UserModel toUserModel(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      groups: entity.groups.map(toUserGroupModel).toList(growable: false),
      avatarUrl: entity.avatarUrl,
      activeGroup: entity.activeGroup != null
          ? toUserGroupModel(entity.activeGroup!)
          : null,
    );
  }

  /// Mengonversi [AuthSessionModel] DTO menjadi [AuthSessionEntity] Domain
  /// dengan sanitasi data.
  static AuthSessionEntity toSessionEntity(AuthSessionModel model) {
    return AuthSessionEntity(
      userId: AppSanitizer.cleanString(model.userId) ?? model.userId.trim(),
      email: AppSanitizer.cleanEmail(model.email) ??
          model.email.trim().toLowerCase(),
      name: AppSanitizer.cleanString(model.name) ?? model.name.trim(),
      allowAdmin: model.allowAdmin,
      allowPatrol: model.allowPatrol,
      allowMonPatrol: model.allowMonPatrol,
      role: AppSanitizer.cleanRole(model.role),
      groupUid: AppSanitizer.cleanString(model.groupUid),
    );
  }

  /// Mengonversi [AuthSessionEntity] Domain menjadi [AuthSessionModel] DTO.
  static AuthSessionModel toSessionModel(AuthSessionEntity entity) {
    return AuthSessionModel(
      userId: entity.userId,
      email: entity.email,
      name: entity.name,
      allowAdmin: entity.allowAdmin,
      allowPatrol: entity.allowPatrol,
      allowMonPatrol: entity.allowMonPatrol,
      role: entity.role,
      groupUid: entity.groupUid,
    );
  }
}

/// Extension helper untuk konversi instan pada [AuthSessionModel].
extension AuthSessionModelX on AuthSessionModel {
  /// Mengonversi DTO ke [AuthSessionEntity].
  AuthSessionEntity toEntity() => AuthMapper.toSessionEntity(this);
}

/// Extension helper untuk konversi instan pada [AuthSessionEntity].
extension AuthSessionEntityX on AuthSessionEntity {
  /// Mengonversi Domain Entity ke [AuthSessionModel].
  AuthSessionModel toModel() => AuthMapper.toSessionModel(this);
}

/// Extension helper untuk konversi instan pada [AuthTokensModel].
extension AuthTokensModelX on AuthTokensModel {
  /// Mengonversi DTO ke [AuthTokensEntity].
  AuthTokensEntity toEntity() => AuthMapper.toTokensEntity(this);
}

/// Extension helper untuk konversi instan pada [AuthTokensEntity].
extension AuthTokensEntityX on AuthTokensEntity {
  /// Mengonversi Domain Entity ke [AuthTokensModel].
  AuthTokensModel toModel() => AuthMapper.toTokensModel(this);
}

/// Extension helper untuk konversi instan pada [UserGroupModel].
extension UserGroupModelX on UserGroupModel {
  /// Mengonversi DTO ke [UserGroupEntity].
  UserGroupEntity toEntity() => AuthMapper.toUserGroupEntity(this);
}

/// Extension helper untuk konversi instan pada [UserGroupEntity].
extension UserGroupEntityX on UserGroupEntity {
  /// Mengonversi Domain Entity ke [UserGroupModel].
  UserGroupModel toModel() => AuthMapper.toUserGroupModel(this);
}

/// Extension helper untuk konversi instan pada [UserModel].
extension UserModelX on UserModel {
  /// Mengonversi DTO ke [UserEntity].
  UserEntity toEntity() => AuthMapper.toUserEntity(this);
}

/// Extension helper untuk konversi instan pada [UserEntity].
extension UserEntityX on UserEntity {
  /// Mengonversi Domain Entity ke [UserModel].
  UserModel toModel() => AuthMapper.toUserModel(this);
}
