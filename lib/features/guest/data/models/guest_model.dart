import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'guest_model.g.dart';

/// Model data DTO murni untuk payload tamu dari API backend (`GuestItemDto`).
///
/// Merupakan Pure DTO tanpa dependensi ke domain entity, tanpa fallback,
/// dan tanpa sanitasi logika bisnis. Selaras 100% dengan skema backend.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class GuestModel extends Equatable {
  const GuestModel({
    required this.id,
    this.groupName,
    this.guestName,
    this.guestNumber,
    this.guestIdentity,
    this.guestIdentityType,
    this.guestPhoto,
    this.guestDt,
    this.guestAckDt,
    this.guestOutDt,
    this.guestPurpose,
    this.guestDestination,
    this.guestToUserEmail,
    this.guestToUserName,
    this.guestCreatorEmail,
    this.guestCreatorName,
    this.guestCategory,
    this.qrUid,
    this.guestAddress,
    this.guestType,
    this.guestCheckoutByEmail,
    this.guestCheckoutByName,
  });

  factory GuestModel.fromJson(Map<String, dynamic> json) =>
      _$GuestModelFromJson(json);

  /// Identifier unik data tamu.
  final String id;

  /// Nama grup kawasan.
  final String? groupName;

  /// Nama lengkap tamu.
  final String? guestName;

  /// Nomor kendaraan atau nomor tamu.
  final String? guestNumber;

  /// Nomor identitas tamu (KTP/SIM/Paspor).
  final String? guestIdentity;

  /// Jenis identitas tamu.
  final String? guestIdentityType;

  /// URL foto tamu.
  final String? guestPhoto;

  /// Waktu kedatangan / pendaftaran tamu.
  final String? guestDt;

  /// Waktu konfirmasi / check-in tamu.
  final String? guestAckDt;

  /// Waktu kepulangan / checkout tamu.
  final String? guestOutDt;

  /// Keperluan kunjungan tamu.
  final String? guestPurpose;

  /// Lokasi / unit yang dituju oleh tamu.
  final String? guestDestination;

  /// Email penghuni atau user yang dituju oleh tamu.
  final String? guestToUserEmail;

  /// Nama penghuni atau user yang dituju oleh tamu.
  final String? guestToUserName;

  /// Email petugas yang mendaftarkan tamu.
  final String? guestCreatorEmail;

  /// Nama petugas yang mendaftarkan tamu.
  final String? guestCreatorName;

  /// Kategori kunjungan tamu.
  final String? guestCategory;

  /// Kode akses QR khusus tamu.
  final String? qrUid;

  /// Alamat asal tamu.
  final String? guestAddress;

  /// Tipe tamu (misal: Kurir, Kontraktor, Tamu Biasa).
  final String? guestType;

  /// Email petugas yang melakukan checkout tamu.
  final String? guestCheckoutByEmail;

  /// Nama petugas yang melakukan checkout tamu.
  final String? guestCheckoutByName;

  @override
  List<Object?> get props => [
    id,
    groupName,
    guestName,
    guestNumber,
    guestIdentity,
    guestIdentityType,
    guestPhoto,
    guestDt,
    guestAckDt,
    guestOutDt,
    guestPurpose,
    guestDestination,
    guestToUserEmail,
    guestToUserName,
    guestCreatorEmail,
    guestCreatorName,
    guestCategory,
    qrUid,
    guestAddress,
    guestType,
    guestCheckoutByEmail,
    guestCheckoutByName,
  ];
}
