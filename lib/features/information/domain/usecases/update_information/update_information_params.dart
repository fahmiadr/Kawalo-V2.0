import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/information_feed_type.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/update_information_data.dart';

/// Command Object (Request Model) untuk mengeksekusi operasi
/// pembaruan data informasi.
///
/// Membungkus input formulir pengguna bersama konteks sesi dan target item
/// untuk verifikasi otorisasi serta integritas ID sebelum dikirim ke repositori
/// data.
class UpdateInformationParams extends Equatable {
  /// Membuat instance [UpdateInformationParams].
  const UpdateInformationParams({
    required this.id,
    this.title,
    this.text,
    this.feedFile,
    this.photos,
    this.feedType,
    this.eventLocation,
    this.glat,
    this.glong,
    this.includeNulls = false,
    this.session,
    this.item,
    this.cancelToken,
  });

  /// Daftar tipe feed yang diizinkan oleh sistem backend.
  static List<String> get allowedFeedTypes => InformationFeedType.allowedCodes;

  /// Pola regex untuk memvalidasi FeedId numerik backend.
  static final RegExp _numericRegex = RegExp(r'^[0-9]+$');

  /// Identifier unik informasi yang akan diperbarui (wajib).
  final String id;

  /// Judul informasi baru (opsional, max 128 karakter).
  final String? title;

  /// Deskripsi isi teks informasi baru (opsional, max 1024 karakter).
  final String? text;

  /// Berkas lampiran feed berupa URL berkas baru (opsional, max 2048 karakter).
  final String? feedFile;

  /// Daftar tautan foto baru yang diunggah (opsional, maksimal 4 berkas).
  final List<String>? photos;

  /// Tipe kategori informasi baru (opsional).
  final String? feedType;

  /// Lokasi acara atau tempat kejadian baru (opsional, max 128 karakter).
  final String? eventLocation;

  /// Garis lintang GPS lokasi (opsional, max 32 karakter).
  final String? glat;

  /// Garis bujur GPS lokasi (opsional, max 32 karakter).
  final String? glong;

  /// Menandakan apakah field opsional dengan nilai `null` tetap disertakan
  /// dalam JSON untuk mengosongkan nilai di backend server.
  final bool includeNulls;

  /// Sesi pengguna aktif yang menjalankan aksi pembaruan.
  final AuthSessionEntity? session;

  /// Entitas informasi target sebelum pembaruan untuk verifikasi otorisasi.
  final InformationItemEntity? item;

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

  /// Memvalidasi apakah format [id] memenuhi kaidah domain dan API backend.
  bool get isValidId => id.isNotEmpty && _numericRegex.hasMatch(id);

  /// Menandakan apakah [session] berhak memperbarui [item] (fail-closed).
  bool get isAuthorized {
    final target = item;
    if (target == null || target.id != id) return false;
    return target.canBeUpdatedBySession(session);
  }

  /// Mengonversi Command Object ke Value Object payload repositori.
  UpdateInformationData toRepositoryData() {
    return UpdateInformationData(
      id: id,
      title: title,
      text: text,
      feedFile: feedFile,
      photos: photos,
      feedType: feedType,
      eventLocation: eventLocation,
      glat: glat,
      glong: glong,
      includeNulls: includeNulls,
      cancelToken: cancelToken,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        text,
        feedFile,
        photos,
        feedType,
        eventLocation,
        glat,
        glong,
        includeNulls,
        session,
        item,
        cancelToken,
      ];
}
