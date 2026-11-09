import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/guest_identity_type.dart';

/// Pure Value Object payload repositori untuk pembaruan data tamu.
///
/// Bertindak sebagai Data Transfer Object di Domain Layer tanpa serialisasi
/// JSON dan independen dari HTTP/Dio.
class UpdateGuestData extends Equatable {
  /// Membuat instance [UpdateGuestData].
  const UpdateGuestData({
    required this.id,
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
    this.cancelToken,
  });

  /// Identifier numerik data tamu yang akan diperbarui (wajib).
  final String id;

  /// Nama tamu baru (opsional).
  final String? guestName;

  /// Lokasi / rumah / blok tujuan kunjungan (opsional).
  final String? guestDestination;

  /// Tipe tamu dari master tipe tamu aktif (opsional).
  final String? guestType;

  /// Keperluan kunjungan tamu (opsional).
  final String? guestPurpose;

  /// Nomor plat kendaraan tamu (opsional).
  final String? guestNumber;

  /// Nomor kartu identitas (opsional).
  final String? guestIdentity;

  /// Jenis kartu identitas (opsional).
  final String? guestIdentityType;

  /// Alamat domisili/asal tamu (opsional).
  final String? guestAddress;

  /// Email penghuni/warga yang dikunjungi (opsional).
  final String? guestToUserEmail;

  /// Foto tamu dalam format URL (opsional).
  final String? guestPhoto;

  /// Menandakan apakah field opsional dengan nilai `null` tetap disertakan
  /// dalam JSON untuk mengosongkan nilai di backend server.
  final bool includeNulls;

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

  /// Jenis identitas tamu yang diizinkan oleh sistem backend.
  static List<String> get allowedIdentityTypes =>
      GuestIdentityType.allowedCodes;

  @override
  List<Object?> get props => [
    id,
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
    cancelToken,
  ];
}
