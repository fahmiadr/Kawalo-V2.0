import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';

/// Entitas bisnis domain murni data feed / informasi dari tabel `tkfeed`.
///
/// Memisahkan informasi yang ditampilkan ke UI (judul, deskripsi, foto,
/// kategori, lokasi, jadwal acara, pengirim) dengan data teknis internal.
class InformationItemEntity extends Equatable {
  /// Membuat instance [InformationItemEntity].
  const InformationItemEntity({
    required this.id,
    required this.photos,
    this.title,
    this.feedDt,
    this.feedType,
    this.userEmail,
    this.text,
    this.userName,
    this.userProfilePic,
    this.feedFile,
    this.groupName,
    this.eventLocation,
    this.eventStartDt,
    this.eventEndDt,
    this.eventDuration,
    this.glat,
    this.glong,
  });

  /// ID unik internal baris data (FeedID).
  final String id;

  /// Daftar berkas foto valid publikasi.
  final List<String> photos;

  /// Judul informasi (FeedTitle).
  final String? title;

  /// Deskripsi isi informasi lengkap (FeedText).
  final String? text;

  /// Email personil pembuat feed (FeedByEmail / user_email).
  final String? userEmail;

  /// Nama personil pembuat feed (FeedByName / user_name).
  final String? userName;

  /// Foto profil pembuat feed (FeedByProfilePic / user_profile_pic).
  final String? userProfilePic;

  /// Waktu pembuatan feed (FeedDT).
  final String? feedDt;

  /// Berkas lampiran feed (FeedFile).
  final String? feedFile;

  /// Tipe informasi (FeedType: GENERAL, INCIDENT, JOIN, EVENT, OTHER).
  final String? feedType;

  /// Nama grup / kawasan (FeedGroupName).
  final String? groupName;

  /// Lokasi acara atau tempat kejadian (FeedEventLocation).
  final String? eventLocation;

  /// Waktu mulai acara (FeedEventStartDT).
  final String? eventStartDt;

  /// Waktu selesai acara (FeedEventEndDT).
  final String? eventEndDt;

  /// Durasi acara dalam hitungan jam/hari (FeedEventDuration).
  final int? eventDuration;

  /// Garis lintang GPS (GLat).
  final double? glat;

  /// Garis bujur GPS (GLong).
  final double? glong;

  /// Memeriksa apakah sesi pengguna aktif memiliki hak akses untuk
  /// membuat feed informasi baru (RBAC).
  ///
  /// Mengikuti aturan otorisasi backend:
  /// - `ADMIN` / `allowAdmin`: Selalu berhak membuat informasi.
  /// - `GUARD` / `allowPatrol`: Selalu berhak membuat informasi.
  /// - Role lain atau sesi `null`: Tidak memiliki akses (fail-closed).
  static bool canBeCreatedBySession(AuthSessionEntity? session) {
    if (session == null) return false;

    final role = session.role?.toUpperCase();
    if (role == 'ADMIN' || session.allowAdmin) return true;
    if (role == 'GUARD' || session.allowPatrol) return true;

    return false;
  }

  /// Memeriksa apakah sesi pengguna aktif memiliki hak akses untuk
  /// menghapus feed informasi ini.
  ///
  /// Mengikuti aturan otorisasi backend (ABAC & RBAC):
  /// - `ADMIN` / `allowAdmin`: Selalu berhak menghapus informasi apapun dalam
  ///   grup.
  /// - `GUARD` / `allowPatrol`: Hanya berhak menghapus informasi yang dibuat
  ///   oleh dirinya sendiri (`userEmail` sama persis dengan email pembuat
  ///   feed).
  /// - Role lain atau sesi `null`: Tidak memiliki akses.
  bool canBeDeletedBySession(AuthSessionEntity? session) {
    if (session == null) return false;

    final role = session.role?.toUpperCase();
    if (role == 'ADMIN' || session.allowAdmin) return true;

    if (role == 'GUARD' || session.allowPatrol) {
      if (userEmail == null || session.email.isEmpty) return false;
      return userEmail!.trim().toLowerCase() ==
          session.email.trim().toLowerCase();
    }

    return false;
  }

  /// Memeriksa apakah sesi pengguna aktif memiliki hak akses untuk
  /// memperbarui feed informasi ini.
  ///
  /// Mengikuti aturan otorisasi backend (ABAC & RBAC):
  /// - `ADMIN` / `allowAdmin`: Selalu berhak mengubah informasi apapun dalam
  ///   grup.
  /// - `GUARD` / `allowPatrol`: Hanya berhak mengubah informasi yang dibuat
  ///   oleh dirinya sendiri (`userEmail` sama persis dengan email pembuat
  ///   feed).
  /// - Role lain atau sesi `null`: Tidak memiliki akses.
  bool canBeUpdatedBySession(AuthSessionEntity? session) {
    if (session == null) return false;

    final role = session.role?.toUpperCase();
    if (role == 'ADMIN' || session.allowAdmin) return true;

    if (role == 'GUARD' || session.allowPatrol) {
      if (userEmail == null || session.email.isEmpty) return false;
      return userEmail!.trim().toLowerCase() ==
          session.email.trim().toLowerCase();
    }

    return false;
  }

  @override
  List<Object?> get props => [
        id,
        photos,
        title,
        text,
        userEmail,
        userName,
        userProfilePic,
        feedDt,
        feedFile,
        feedType,
        groupName,
        eventLocation,
        eventStartDt,
        eventEndDt,
        eventDuration,
        glat,
        glong,
      ];
}
