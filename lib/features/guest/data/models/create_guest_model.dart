import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_guest_model.g.dart';

/// Pure DTO model untuk payload pendaftaran tamu baru (`CreateGuestDto`).
///
/// Digunakan untuk serialisasi HTTP POST `/v1/guests`.
/// Dilarang keras mengimpor Domain Entity ke dalam file ini.
@JsonSerializable(
  createFactory: false,
  includeIfNull: false,
  fieldRename: FieldRename.snake,
)
class CreateGuestModel extends Equatable {
  /// Membuat instance [CreateGuestModel].
  const CreateGuestModel({
    required this.guestName,
    required this.guestDestination,
    required this.guestType,
    this.guestPurpose,
    this.guestNumber,
    this.guestIdentity,
    this.guestIdentityType,
    this.guestAddress,
    this.guestToUserEmail,
    this.guestToName,
    this.guestPhoto,
    this.guestDt,
  });

  /// Nama tamu (wajib).
  final String guestName;

  /// Lokasi/rumah/blok tujuan tamu (wajib).
  final String guestDestination;

  /// Tipe tamu dari master tipe tamu grup aktif (wajib).
  final String guestType;

  /// Keperluan kunjungan tamu (opsional).
  final String? guestPurpose;

  /// Nomor plat kendaraan tamu (opsional).
  final String? guestNumber;

  /// Nomor identitas KTP/SIM/Paspor (opsional).
  final String? guestIdentity;

  /// Jenis kartu identitas (opsional).
  final String? guestIdentityType;

  /// Alamat domisili/asal tamu (opsional).
  final String? guestAddress;

  /// Email penghuni yang dikunjungi (opsional).
  final String? guestToUserEmail;

  /// Nama tuan rumah yang diketik bebas (opsional, max 128 karakter).
  final String? guestToName;

  /// Foto tamu dalam format URL (opsional).
  final String? guestPhoto;

  /// Waktu kedatangan tamu ISO 8601 (opsional).
  final String? guestDt;

  /// Mengonversi DTO ke Map JSON untuk dikirim melalui HTTP client.
  Map<String, dynamic> toJson() => _$CreateGuestModelToJson(this);

  // Keeps Equatable's own getters out of the generated JSON.
  @override
  @JsonKey(includeToJson: false)
  bool? get stringify => super.stringify;

  @override
  @JsonKey(includeToJson: false)
  List<Object?> get props => [
    guestName,
    guestDestination,
    guestType,
    guestPurpose,
    guestNumber,
    guestIdentity,
    guestIdentityType,
    guestAddress,
    guestToUserEmail,
    guestToName,
    guestPhoto,
    guestDt,
  ];
}
