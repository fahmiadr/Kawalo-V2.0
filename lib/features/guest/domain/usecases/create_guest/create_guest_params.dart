import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/create_guest_data.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/guest_identity_type.dart';

/// Command Object parameter domain untuk pendaftaran tamu baru
/// (`CreateGuestDto`).
///
/// Bertindak sebagai Request Model murni di Domain Layer yang digunakan
/// oleh UseCase dan Repository tanpa terikat ke format teknis HTTP.
class CreateGuestParams extends Equatable {
  /// Membuat instance [CreateGuestParams].
  const CreateGuestParams({
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
    this.session,
    this.cancelToken,
  });

  /// Jenis identitas tamu yang diizinkan oleh sistem backend
  /// (`GuestIdentityTypeEnum`).
  static List<String> get allowedIdentityTypes =>
      GuestIdentityType.allowedCodes;

  /// Nama lengkap tamu (wajib, max 128 karakter).
  final String guestName;

  /// Lokasi / rumah / blok tujuan kunjungan (wajib, max 128 karakter).
  final String guestDestination;

  /// Tipe tamu dari master tipe tamu aktif (wajib, max 64 karakter).
  final String guestType;

  /// Keperluan kunjungan tamu (opsional, max 128 karakter).
  final String? guestPurpose;

  /// Nomor plat kendaraan tamu (opsional, max 32 karakter).
  final String? guestNumber;

  /// Nomor kartu identitas (opsional, max 64 karakter).
  final String? guestIdentity;

  /// Jenis kartu identitas ('KTP', 'SIM', 'PASPOR', 'LAINNYA', opsional).
  final String? guestIdentityType;

  /// Alamat domisili/asal tamu (opsional, max 512 karakter).
  final String? guestAddress;

  /// Email penghuni/warga yang dikunjungi (opsional, max 128 karakter).
  final String? guestToUserEmail;

  /// Foto tamu dalam format URL (opsional, max 2048 karakter).
  final String? guestPhoto;

  /// Waktu kedatangan tamu ISO 8601 (opsional).
  final String? guestDt;

  /// Sesi pengguna aktif yang menjalankan aksi (opsional).
  final AuthSessionEntity? session;

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

  /// Menandakan apakah pengguna berhak mendaftarkan tamu baru.
  bool get isAuthorized => GuestItemEntity.canBeCreatedBySession(session);

  /// Mengonversi Command Object ke Value Object payload repositori.
  CreateGuestData toRepositoryData() {
    return CreateGuestData(
      guestName: guestName,
      guestDestination: guestDestination,
      guestType: guestType,
      guestPurpose: guestPurpose,
      guestNumber: guestNumber,
      guestIdentity: guestIdentity,
      guestIdentityType: guestIdentityType,
      guestAddress: guestAddress,
      guestToUserEmail: guestToUserEmail,
      guestPhoto: guestPhoto,
      guestDt: guestDt,
      cancelToken: cancelToken,
    );
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
        session,
        cancelToken,
      ];
}
