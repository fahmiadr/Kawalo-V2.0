import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/create_information_data.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/information_feed_type.dart';

/// Command Object (Request Model) untuk mengeksekusi operasi
/// pembuatan informasi baru.
///
/// Membungkus input formulir pengguna bersama konteks sesi untuk evaluasi
/// aturan otorisasi di lapisan Use Case.
class CreateInformationParams extends Equatable {
  /// Membuat instance [CreateInformationParams].
  const CreateInformationParams({
    required this.title,
    this.text,
    this.feedFile,
    this.photos,
    this.feedType,
    this.eventLocation,
    this.glat,
    this.glong,
    this.session,
    this.cancelToken,
  });

  /// Daftar tipe feed yang diizinkan oleh sistem backend.
  static List<String> get allowedFeedTypes => InformationFeedType.allowedCodes;

  /// Judul informasi (wajib, max 128 karakter).
  final String title;

  /// Deskripsi isi teks informasi (opsional, max 1024 karakter).
  final String? text;

  /// Berkas lampiran feed berupa URL berkas (opsional, max 2048 karakter).
  final String? feedFile;

  /// Daftar tautan foto yang diunggah (opsional, maksimal 4 berkas).
  final List<String>? photos;

  /// Tipe kategori informasi (opsional, default backend: 'OTHER').
  final String? feedType;

  /// Lokasi acara atau tempat kejadian (opsional, max 128 karakter).
  final String? eventLocation;

  /// Garis lintang GPS lokasi (opsional, max 32 karakter).
  final String? glat;

  /// Garis bujur GPS lokasi (opsional, max 32 karakter).
  final String? glong;

  /// Sesi pengguna aktif yang menjalankan aksi pembuatan informasi.
  final AuthSessionEntity? session;

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

  /// Menandakan apakah pengguna berhak membuat informasi (fail-closed).
  bool get isAuthorized => InformationItemEntity.canBeCreatedBySession(session);

  /// Mengonversi Command Object ke Value Object payload repositori.
  CreateInformationData toRepositoryData() {
    return CreateInformationData(
      title: title,
      text: text,
      feedFile: feedFile,
      photos: photos,
      feedType: feedType,
      eventLocation: eventLocation,
      glat: glat,
      glong: glong,
      cancelToken: cancelToken,
    );
  }

  @override
  List<Object?> get props => [
        title,
        text,
        feedFile,
        photos,
        feedType,
        eventLocation,
        glat,
        glong,
        session,
        cancelToken,
      ];
}
