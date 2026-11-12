import 'package:equatable/equatable.dart';

/// Pure Domain Entity yang merepresentasikan anggota dalam grup aktif.
///
/// Mengonsolidasikan seluruh kebutuhan identitas pengguna grup lintas fitur
/// (filter penulis di Informasi, filter pembuat & tuan rumah di Tamu, penugasan
/// di Operasional) dengan prinsip zero legacy.
class GroupMemberEntity extends Equatable {
  /// Membuat instance [GroupMemberEntity].
  const GroupMemberEntity({
    required this.email,
    this.name,
    this.profilePic,
    this.role,
  });

  /// Alamat email unik pengguna anggota grup.
  final String email;

  /// Nama lengkap anggota grup (opsional).
  final String? name;

  /// URL foto profil anggota grup (opsional).
  final String? profilePic;

  /// Upper-case category in the active group (`ADMIN`, `GUARD`, `USER`);
  /// `null` when the server does not send it.
  final String? role;

  /// Label nama tampilan untuk antarmuka pengguna (fallback ke email).
  String get displayName =>
      (name != null && name!.trim().isNotEmpty) ? name! : email;

  /// Label tampilan gabungan nama dan email untuk dropdown / pemilih host.
  String get displayLabel {
    if (name != null && name!.trim().isNotEmpty) {
      return '$name ($email)';
    }
    return email;
  }

  /// Label gabungan yang ramah pencarian teks lokal.
  String get displaySearchLabel {
    if (name != null && name!.trim().isNotEmpty) {
      return '$name $email';
    }
    return email;
  }

  @override
  List<Object?> get props => [email, name, profilePic, role];
}
