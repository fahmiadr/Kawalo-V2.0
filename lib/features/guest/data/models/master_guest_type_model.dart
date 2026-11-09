import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'master_guest_type_model.g.dart';

/// Pure DTO model untuk satu item master tipe tamu (`MasterGuestTypeItemDto`).
///
/// Digunakan untuk deserialisasi response `GET /v1/guests/master-types`.
@JsonSerializable(createToJson: false)
class MasterGuestTypeModel extends Equatable {
  const MasterGuestTypeModel({
    required this.id,
    required this.uid,
    required this.name,
  });

  factory MasterGuestTypeModel.fromJson(Map<String, dynamic> json) =>
      _$MasterGuestTypeModelFromJson(json);

  /// ID master tipe tamu.
  final String id;

  /// UID master tipe tamu.
  final String uid;

  /// Nama tipe tamu (misal: "TAMU", "KURIR", "PENGUNJUNG").
  final String name;

  @override
  List<Object?> get props => [id, uid, name];
}
