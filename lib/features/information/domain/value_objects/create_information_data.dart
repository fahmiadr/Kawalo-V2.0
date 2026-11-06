import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/information_feed_type.dart';

/// Value object payload data untuk operasi pembuatan informasi / feed baru
/// pada repositori.
///
/// Bertindak sebagai murni Value Object tanpa identitas independen dan
/// bebas dari konteks otorisasi sesi presentasi.
class CreateInformationData extends Equatable {
  /// Membuat instance [CreateInformationData].
  const CreateInformationData({
    required this.title,
    this.text,
    this.feedFile,
    this.photos,
    this.feedType,
    this.eventLocation,
    this.glat,
    this.glong,
    this.cancelToken,
  });

  /// Daftar kode feed type yang diizinkan oleh sistem backend.
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

  /// Token pembatalan request (opsional).
  final AppCancellationToken? cancelToken;

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
        cancelToken,
      ];
}
