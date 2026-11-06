import 'package:equatable/equatable.dart';

/// Entity domain murni untuk master tipe tamu.
///
/// Mewakili satu entitas tipe tamu yang sah dari database grup aktif.
class MasterGuestTypeEntity extends Equatable {
  /// Membuat instance [MasterGuestTypeEntity].
  const MasterGuestTypeEntity({
    required this.id,
    required this.uid,
    required this.name,
  });

  /// ID numerik / record string tipe tamu.
  final String id;

  /// UID unik master tipe tamu.
  final String uid;

  /// Nama label tipe tamu (misal: "TAMU", "KURIR", "PENGUNJUNG").
  final String name;

  @override
  List<Object?> get props => [id, uid, name];
}
