import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/guest_identity_type.dart';

/// Value object payload data untuk operasi pendaftaran tamu baru pada
/// repositori.
///
/// Bertindak sebagai murni Value Object tanpa identitas independen dan
/// bebas dari konteks otorisasi sesi presentasi.
class CreateGuestData extends Equatable {
  /// Membuat instance [CreateGuestData].
  const CreateGuestData({
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
    this.cancelToken,
  });

  /// Daftar jenis identitas yang diizinkan oleh sistem backend.
  static List<String> get allowedIdentityTypes =>
      GuestIdentityType.allowedCodes;

  /// Nama lengkap tamu (wajib).
  final String guestName;

  /// Lokasi / rumah / blok tujuan kunjungan (wajib).
  final String guestDestination;

  /// Tipe tamu dari master tipe tamu aktif (wajib).
  final String guestType;

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

  /// Waktu kedatangan tamu ISO 8601 (opsional).
  final String? guestDt;

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

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
        cancelToken,
      ];
}
