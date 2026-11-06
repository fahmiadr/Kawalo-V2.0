import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/guest_identity_type.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/update_guest_data.dart';

/// Command Object (Request Model) untuk mengeksekusi operasi
/// pembaruan data tamu.
///
/// Membungkus input formulir pengguna bersama konteks sesi dan target item
/// untuk verifikasi otorisasi serta integritas ID sebelum dikirim ke repositori
/// data.
class UpdateGuestParams extends Equatable {
  /// Membuat instance [UpdateGuestParams].
  const UpdateGuestParams({
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
    this.session,
    this.item,
    this.cancelToken,
  });

  /// Pola regex untuk memvalidasi GuestId numerik backend.
  static final RegExp _numericRegex = RegExp(r'^[0-9]+$');

  /// Identifier numerik data tamu yang akan diperbarui (wajib).
  final String id;

  /// Nama lengkap tamu baru (opsional, max 128 karakter).
  final String? guestName;

  /// Lokasi / rumah / blok tujuan kunjungan baru (opsional, max 128 karakter).
  final String? guestDestination;

  /// Tipe tamu dari master tipe tamu aktif baru (opsional, max 64 karakter).
  final String? guestType;

  /// Keperluan kunjungan tamu baru (opsional, max 128 karakter).
  final String? guestPurpose;

  /// Nomor plat kendaraan baru (opsional, max 32 karakter).
  final String? guestNumber;

  /// Nomor kartu identitas baru (opsional, max 64 karakter).
  final String? guestIdentity;

  /// Jenis kartu identitas baru (opsional).
  final String? guestIdentityType;

  /// Alamat domisili/asal tamu baru (opsional, max 512 karakter).
  final String? guestAddress;

  /// Email penghuni/warga yang dikunjungi baru (opsional, max 128 karakter).
  final String? guestToUserEmail;

  /// Foto tamu dalam format URL baru (opsional, max 2048 karakter).
  final String? guestPhoto;

  /// Menandakan apakah field opsional dengan nilai `null` tetap disertakan
  /// dalam JSON untuk mengosongkan nilai di backend server.
  final bool includeNulls;

  /// Sesi pengguna aktif yang menjalankan aksi pembaruan.
  final AuthSessionEntity? session;

  /// Entitas tamu target sebelum pembaruan untuk verifikasi otorisasi.
  final GuestItemEntity? item;

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

  /// Jenis identitas tamu yang diizinkan oleh sistem backend.
  static List<String> get allowedIdentityTypes =>
      GuestIdentityType.allowedCodes;

  /// Memvalidasi apakah format [id] berupa angka valid dan tidak kosong.
  bool get isValidId => id.isNotEmpty && _numericRegex.hasMatch(id);

  /// Menandakan apakah [session] berhak memperbarui [item] (fail-closed).
  bool get isAuthorized {
    final target = item;
    if (target == null || target.id != id) return false;
    return target.canBeUpdatedBySession(session);
  }

  /// Mengonversi Command Object ke Value Object payload repositori.
  UpdateGuestData toRepositoryData() {
    return UpdateGuestData(
      id: id,
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
      includeNulls: includeNulls,
      cancelToken: cancelToken,
    );
  }

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
        session,
        item,
        cancelToken,
      ];
}
