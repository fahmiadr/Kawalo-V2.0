import 'package:equatable/equatable.dart';

/// Pure DTO model untuk satu item master tipe tamu (`MasterGuestTypeItemDto`).
///
/// Digunakan untuk deserialisasi response `GET /v1/guests/master-types`.
class MasterGuestTypeModel extends Equatable {
  /// Membuat instance [MasterGuestTypeModel].
  const MasterGuestTypeModel({
    required this.id,
    required this.uid,
    required this.name,
  });

  /// Mengonversi dari Map JSON API backend.
  factory MasterGuestTypeModel.fromJson(Map<String, dynamic> json) {
    return MasterGuestTypeModel(
      id: json['id'] as String,
      uid: json['uid'] as String,
      name: json['name'] as String,
    );
  }

  /// ID master tipe tamu.
  final String id;

  /// UID master tipe tamu.
  final String uid;

  /// Nama tipe tamu (misal: "TAMU", "KURIR", "PENGUNJUNG").
  final String name;

  @override
  List<Object?> get props => [id, uid, name];
}
