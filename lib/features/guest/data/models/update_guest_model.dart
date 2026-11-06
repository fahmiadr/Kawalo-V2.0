import 'package:equatable/equatable.dart';

/// Pure DTO model untuk payload pembaruan data tamu (`UpdateGuestDto`).
///
/// Digunakan untuk serialisasi HTTP PUT/PATCH `/v1/guests/:id`.
/// Dilarang keras mengimpor Domain Entity ke dalam file ini.
class UpdateGuestModel extends Equatable {
  /// Membuat instance [UpdateGuestModel].
  const UpdateGuestModel({
    this.guestName,
    this.guestDestination,
    this.guestType,
    this.guestPurpose,
    this.guestNumber,
    this.guestIdentity,
    this.guestIdentityType,
    this.guestAddress,
    this.guestToUserEmail,
    this.guestPhoto,
    this.includeNulls = false,
  });

  /// Nama tamu baru (opsional).
  final String? guestName;

  /// Lokasi/rumah/blok tujuan baru (opsional).
  final String? guestDestination;

  /// Tipe tamu dari master tipe tamu grup aktif baru (opsional).
  final String? guestType;

  /// Keperluan kunjungan tamu baru (opsional).
  final String? guestPurpose;

  /// Nomor plat kendaraan baru (opsional).
  final String? guestNumber;

  /// Nomor kartu identitas baru (opsional).
  final String? guestIdentity;

  /// Jenis kartu identitas baru (opsional).
  final String? guestIdentityType;

  /// Alamat domisili/asal tamu baru (opsional).
  final String? guestAddress;

  /// Email penghuni yang dikunjungi baru (opsional).
  final String? guestToUserEmail;

  /// Foto tamu dalam format URL baru (opsional).
  final String? guestPhoto;

  /// Menandakan apakah field opsional dengan nilai `null` tetap disertakan
  /// dalam JSON untuk mengosongkan nilai di backend server.
  final bool includeNulls;

  /// Mengonversi DTO ke Map JSON untuk dikirim melalui HTTP client.
  Map<String, dynamic> toJson() {
    if (includeNulls) {
      return {
        if (guestName != null) 'guest_name': guestName,
        if (guestDestination != null) 'guest_destination': guestDestination,
        if (guestType != null) 'guest_type': guestType,
        'guest_purpose': guestPurpose,
        'guest_number': guestNumber,
        'guest_identity': guestIdentity,
        'guest_identity_type': guestIdentityType,
        'guest_address': guestAddress,
        'guest_to_user_email': guestToUserEmail,
        'guest_photo': guestPhoto,
      };
    }
    return {
      if (guestName != null) 'guest_name': guestName,
      if (guestDestination != null) 'guest_destination': guestDestination,
      if (guestType != null) 'guest_type': guestType,
      if (guestPurpose != null) 'guest_purpose': guestPurpose,
      if (guestNumber != null) 'guest_number': guestNumber,
      if (guestIdentity != null) 'guest_identity': guestIdentity,
      if (guestIdentityType != null) 'guest_identity_type': guestIdentityType,
      if (guestAddress != null) 'guest_address': guestAddress,
      if (guestToUserEmail != null) 'guest_to_user_email': guestToUserEmail,
      if (guestPhoto != null) 'guest_photo': guestPhoto,
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
        includeNulls,
      ];
}
