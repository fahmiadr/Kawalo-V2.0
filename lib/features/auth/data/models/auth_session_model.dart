import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_session_model.g.dart';

/// Model DTO untuk serialisasi sesi autentikasi pengguna dari klaim JWT
/// atau penyimpanan lokal aman (Secure Storage).
@JsonSerializable(fieldRename: FieldRename.snake, checked: true)
class AuthSessionModel extends Equatable {
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

  /// Builds the session from verified JWT claims.
  ///
  /// Throws [FormatException] when a mandatory claim (`sub`, `email`, `name`)
  /// is missing or not a string; callers treat that as an invalid token.
  /// Missing `allow_*` flags become `false` so a malformed token can only
  /// lose access, never gain it.
  factory AuthSessionModel.fromJwtPayload(Map<String, dynamic> payload) {
    String requiredClaim(String claim) {
      final value = payload[claim];
      if (value is String && value.isNotEmpty) return value;
      throw FormatException('Klaim JWT "$claim" tidak ada atau tidak valid.');
    }

    String? optionalClaim(String claim) {
      final value = payload[claim];
      return value is String ? value : null;
    }

    return AuthSessionModel(
      userId: requiredClaim('sub'),
      email: requiredClaim('email'),
      name: requiredClaim('name'),
      role: optionalClaim('role'),
      groupUid: optionalClaim('group_uid'),
      allowAdmin: payload['allow_admin'] == true,
      allowPatrol: payload['allow_patrol'] == true,
      allowMonPatrol: payload['allow_mon_patrol'] == true,
    );
  }

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) =>
      _$AuthSessionModelFromJson(json);

  /// ID unik pengguna (`sub`).
  final String userId;
  final String email;
  final String name;

  /// Role aktif pengguna pada grup saat ini.
  final String? role;

  /// UID grup aktif sesi saat ini.
  final String? groupUid;

  @JsonKey(defaultValue: false)
  final bool allowAdmin;

  @JsonKey(defaultValue: false)
  final bool allowPatrol;

  @JsonKey(defaultValue: false)
  final bool allowMonPatrol;

  Map<String, dynamic> toJson() => _$AuthSessionModelToJson(this);

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
