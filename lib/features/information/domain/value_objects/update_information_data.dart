import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/information_feed_type.dart';

/// Value object payload data untuk operasi pembaruan data informasi / feed
/// pada repositori.
///
/// Bertindak sebagai murni Value Object tanpa dependensi konteks otorisasi sesi
/// atau entitas pembanding sebelum pembaruan.
class UpdateInformationData extends Equatable {
  /// Membuat instance [UpdateInformationData].
  const UpdateInformationData({
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
    this.cancelToken,
  });

  /// Daftar kode feed type yang diizinkan oleh sistem backend.
  static List<String> get allowedFeedTypes => InformationFeedType.allowedCodes;

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

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

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
    cancelToken,
  ];
}
