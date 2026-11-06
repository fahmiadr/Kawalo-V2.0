import 'package:isar_community/isar.dart';

part 'guest_local_model.g.dart';

/// Skema tabel lokal Isar untuk persistensi data tamu (guest).
///
/// Urutan field identik dengan DTO backend dan model domain data.
@collection
class GuestLocalModel {
  /// Primary key internal Isar.
  Id isarId = Isar.autoIncrement;

  /// Identifier unik data tamu (id).
  @Index(unique: true, replace: true)
  late String id;

  /// Nama lengkap tamu (guest_name).
  @Index(caseSensitive: false)
  String? guestName;

  /// Nomor kendaraan atau nomor tamu (guest_number).
  @Index(caseSensitive: false)
  String? guestNumber;

  /// Nomor identitas tamu seperti KTP/SIM/Paspor (guest_identity).
  @Index(caseSensitive: false)
  String? guestIdentity;

  /// Jenis identitas tamu (guest_identity_type).
  @Index(caseSensitive: false)
  String? guestIdentityType;

  /// Waktu kedatangan tamu dalam format ISO 8601 (guest_dt).
  @Index()
  String? guestDt;

  /// Keperluan kunjungan tamu (guest_purpose).
  @Index(caseSensitive: false)
  String? guestPurpose;

  /// Lokasi / unit tujuan tamu (guest_destination).
  @Index(caseSensitive: false)
  String? guestDestination;

  /// Email user / penghuni yang dituju tamu (guest_to_user_email).
  @Index(caseSensitive: false)
  String? guestToUserEmail;

  /// Nama user / penghuni yang dituju tamu (guest_to_user_name).
  @Index(caseSensitive: false)
  String? guestToUserName;

  /// Email petugas pembuat tiket tamu (guest_creator_email).
  @Index(caseSensitive: false)
  String? guestCreatorEmail;

  /// Nama petugas pembuat tiket tamu (guest_creator_name).
  @Index(caseSensitive: false)
  String? guestCreatorName;

  /// Kategori kunjungan tamu (guest_category).
  @Index(caseSensitive: false)
  String? guestCategory;

  /// Kode akses QR khusus tamu (qr_uid).
  @Index(caseSensitive: false)
  String? qrUid;

  /// Alamat domisili atau asal tamu (guest_address).
  @Index(caseSensitive: false)
  String? guestAddress;

  /// Tipe tamu (guest_type).
  @Index(caseSensitive: false)
  String? guestType;

  /// Email petugas yang melakukan checkout tamu (guest_checkout_by_email).
  @Index(caseSensitive: false)
  String? guestCheckoutByEmail;

  /// Nama petugas yang melakukan checkout tamu (guest_checkout_by_name).
  @Index(caseSensitive: false)
  String? guestCheckoutByName;

  /// Nama grup kawasan (group_name).
  String? groupName;

  /// URL foto tamu (guest_photo).
  String? guestPhoto;

  /// Waktu konfirmasi check-in tamu (guest_ack_dt).
  String? guestAckDt;

  /// Waktu kepulangan / checkout tamu (guest_out_dt).
  String? guestOutDt;
}
