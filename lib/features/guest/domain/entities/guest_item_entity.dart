import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';

/// Entitas domain murni yang merepresentasikan data satu tamu.
///
/// Merupakan Pure Business Object (100% pure Dart, independen dari framework
/// UI/Dio), immutable, dan selaras dengan DTO data model (`GuestModel`).
class GuestItemEntity extends Equatable {
  /// Membuat instance [GuestItemEntity].
  const GuestItemEntity({
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

  /// Memeriksa apakah sesi pengguna aktif memiliki hak akses untuk
  /// menghapus data tamu ini.
  ///
  /// Mengikuti aturan otorisasi backend (ABAC & RBAC):
  /// - `ADMIN` / `allowAdmin`: Selalu berhak menghapus data tamu apapun dalam
  ///   grup.
  /// - `GUARD` / `allowPatrol`: Hanya berhak menghapus data tamu yang dibuat
  ///   oleh dirinya sendiri (`guestCreatorEmail` sama persis dengan email
  ///   pembuat).
  /// - Role lain atau sesi `null`: Tidak memiliki akses.
  bool canBeDeletedBySession(AuthSessionEntity? session) {
    if (session == null) return false;

    final role = session.role?.toUpperCase();
    if (role == 'ADMIN' || session.allowAdmin) return true;

    if (role == 'GUARD' || session.allowPatrol) {
      if (guestCreatorEmail == null || session.email.isEmpty) return false;
      return guestCreatorEmail!.trim().toLowerCase() ==
          session.email.trim().toLowerCase();
    }

    return false;
  }

  /// Memeriksa apakah sesi pengguna aktif memiliki hak akses untuk
  /// memperbarui data tamu ini.
  ///
  /// Mengikuti aturan otorisasi backend (ABAC & RBAC):
  /// - `ADMIN` / `allowAdmin`: Selalu berhak mengubah data tamu apapun dalam
  ///   grup.
  /// - `GUARD` / `allowPatrol`: Hanya berhak mengubah data tamu yang dibuat
  ///   oleh dirinya sendiri (`guestCreatorEmail` sama persis dengan email
  ///   pembuat).
  /// - Role lain atau sesi `null`: Tidak memiliki akses.
  bool canBeUpdatedBySession(AuthSessionEntity? session) {
    if (session == null) return false;

    final role = session.role?.toUpperCase();
    if (role == 'ADMIN' || session.allowAdmin) return true;

    if (role == 'GUARD' || session.allowPatrol) {
      if (guestCreatorEmail == null || session.email.isEmpty) return false;
      return guestCreatorEmail!.trim().toLowerCase() ==
          session.email.trim().toLowerCase();
    }

    return false;
  }

  /// Menentukan apakah tamu telah keluar dari kawasan (check-out selesai).
  bool get isExited =>
      guestOutDt != null && guestOutDt!.isNotEmpty && guestOutDt != '-';

  /// Menentukan apakah kunjungan tamu sudah dikonfirmasi.
  bool get isAcknowledged =>
      guestAckDt != null && guestAckDt!.isNotEmpty && guestAckDt != '-';

  /// Memeriksa apakah sesi pengguna aktif boleh mengonfirmasi kunjungan tamu
  /// ini.
  ///
  /// Mengikuti backend `PATCH /guests/:id/acknowledge`:
  /// - Tamu belum keluar dan belum dikonfirmasi.
  /// - `ADMIN` / `GUARD` boleh mengonfirmasi tamu apa pun dalam grup.
  /// - Penghuni lain hanya boleh bila ia adalah penghuni tujuan
  ///   (`guestToUserEmail` sama dengan email sesi).
  bool canBeAcknowledgedBySession(AuthSessionEntity? session) {
    if (session == null || isExited || isAcknowledged) return false;

    final role = session.role?.toUpperCase();
    if (role == 'ADMIN' || session.allowAdmin) return true;
    if (role == 'GUARD' || session.allowPatrol) return true;

    final host = guestToUserEmail?.trim().toLowerCase();
    return host != null &&
        host.isNotEmpty &&
        host == session.email.trim().toLowerCase();
  }

  /// Memeriksa apakah sesi pengguna aktif memiliki hak akses untuk
  /// melakukan check-out data tamu ini.
  ///
  /// Mengikuti aturan otorisasi backend (RBAC):
  /// - Tamu belum checkout (`!isExited`).
  /// - `ADMIN` / `allowAdmin`: Berhak checkout tamu.
  /// - `GUARD` / `allowPatrol`: Berhak checkout tamu.
  /// - Role lain atau sesi `null`: Tidak memiliki akses.
  bool canBeCheckedOutBySession(AuthSessionEntity? session) {
    if (session == null) return false;
    if (isExited) return false;

    final role = session.role?.toUpperCase();
    if (role == 'ADMIN' || session.allowAdmin) return true;
    if (role == 'GUARD' || session.allowPatrol) return true;

    return false;
  }

  /// Memeriksa apakah sesi pengguna aktif memiliki hak akses untuk
  /// mendaftarkan data tamu baru.
  ///
  /// Mengikuti aturan otorisasi backend (RBAC):
  /// - `ADMIN` / `allowAdmin`: Selalu berhak mendaftarkan data tamu.
  /// - `GUARD` / `allowPatrol`: Selalu berhak mendaftarkan data tamu.
  /// - Role lain atau sesi `null`: Tidak memiliki akses.
  static bool canBeCreatedBySession(AuthSessionEntity? session) {
    if (session == null) return false;

    final role = session.role?.toUpperCase();
    if (role == 'ADMIN' || session.allowAdmin) return true;
    if (role == 'GUARD' || session.allowPatrol) return true;

    return false;
  }
}
