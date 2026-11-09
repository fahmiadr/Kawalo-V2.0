import 'package:equatable/equatable.dart';

/// Pure DTO model untuk payload pendaftaran tamu baru (`CreateGuestDto`).
///
/// Digunakan untuk serialisasi HTTP POST `/v1/guests`.
/// Dilarang keras mengimpor Domain Entity ke dalam file ini.
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

  /// Foto tamu dalam format URL (opsional).
  final String? guestPhoto;

  /// Waktu kedatangan tamu ISO 8601 (opsional).
  final String? guestDt;

  /// Mengonversi DTO ke Map JSON untuk dikirim melalui HTTP client.
  Map<String, dynamic> toJson() {
    return {
      'guest_name': guestName,
      'guest_destination': guestDestination,
      'guest_type': guestType,
      if (guestPurpose != null) 'guest_purpose': guestPurpose,
      if (guestNumber != null) 'guest_number': guestNumber,
      if (guestIdentity != null) 'guest_identity': guestIdentity,
      if (guestIdentityType != null) 'guest_identity_type': guestIdentityType,
      if (guestAddress != null) 'guest_address': guestAddress,
      if (guestToUserEmail != null) 'guest_to_user_email': guestToUserEmail,
      if (guestPhoto != null) 'guest_photo': guestPhoto,
      if (guestDt != null) 'guest_dt': guestDt,
    };
  }

  @override
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
    guestPhoto,
    guestDt,
  ];
}
