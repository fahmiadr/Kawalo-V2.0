import 'package:equatable/equatable.dart';

/// A member currently connected to the group's PTT channel.
class PttMemberEntity extends Equatable {
  const PttMemberEntity({
    required this.userId,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.speaking = false,
  });

  final String userId;
  final String name;
  final String role;
  final String? avatarUrl;

  /// Floor holder at the moment the list was fetched. The UI derives the live
  /// speaker from the floor state instead, so this only seeds a fresh fetch.
  final bool speaking;

  String get roleLabel => switch (role.trim().toUpperCase()) {
    'ADMIN' || 'SUPER_ADMIN' => 'Admin',
    'GUARD' => 'Petugas',
    '' => 'Anggota',
    final other => other,
  };

  @override
  List<Object?> get props => [userId, name, role, avatarUrl, speaking];
}
