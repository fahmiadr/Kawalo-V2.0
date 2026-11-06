import 'package:equatable/equatable.dart';

/// Model request keluar (outbound DTO) untuk berganti grup aktif
/// (`SwitchGroupDto`).
///
/// Merupakan Outbound Pure DTO yang hanya memiliki serialisasi ke luar
/// ([toJson]) dan tidak memiliki deserialisasi `fromJson`.
class SwitchGroupRequestModel extends Equatable {
  /// Membuat instance [SwitchGroupRequestModel].
  const SwitchGroupRequestModel({
    required this.groupUid,
  });

  /// Target Group UID yang akan diaktifkan.
  final String groupUid;

  /// Mengonversi payload menjadi representasi JSON outbound untuk dikirim ke
  /// backend API (`POST /v1/auth/switch-group`).
  Map<String, dynamic> toJson() {
    return {
      'group_uid': groupUid,
    };
  }

  @override
  List<Object?> get props => [groupUid];
}
