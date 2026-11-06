import 'package:equatable/equatable.dart';

/// Pure DTO model untuk representasi JSON data anggota grup dari API.
class GroupMemberModel extends Equatable {
  /// Membuat instance [GroupMemberModel].
  const GroupMemberModel({
    required this.email,
    this.name,
    this.profilePic,
  });

  /// Factory untuk memetakan JSON payload response API ke [GroupMemberModel].
  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      email: json['email'] as String,
      name: json['name'] as String?,
      profilePic: json['profilePic'] as String?,
    );
  }

  /// Alamat email anggota grup.
  final String email;

  /// Nama anggota grup (opsional).
  final String? name;

  /// URL foto profil anggota (opsional).
  final String? profilePic;

  @override
  List<Object?> get props => [email, name, profilePic];
}
