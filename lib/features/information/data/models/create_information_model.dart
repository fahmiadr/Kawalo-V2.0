import 'package:equatable/equatable.dart';

/// Pure DTO model untuk payload pembuatan informasi baru
/// (`CreateInformationDto`).
///
/// Digunakan untuk serialisasi HTTP POST `/v1/information`.
/// Dilarang keras mengimpor Domain Entity ke dalam file ini.
class CreateInformationModel extends Equatable {
  /// Membuat instance [CreateInformationModel].
  const CreateInformationModel({
    required this.title,
    this.text,
    this.feedFile,
    this.photos,
    this.feedType,
    this.eventLocation,
    this.glat,
    this.glong,
  });

  /// Judul informasi (wajib).
  final String title;

  /// Isi teks informasi (opsional).
  final String? text;

  /// Berkas lampiran feed URL (opsional).
  final String? feedFile;

  /// Daftar URL/nama foto (opsional, maksimal 4 item).
  final List<String>? photos;

  /// Tipe kategori informasi (opsional).
  final String? feedType;

  /// Lokasi acara/kegiatan (opsional).
  final String? eventLocation;

  /// Garis lintang lokasi (opsional).
  final String? glat;

  /// Garis bujur lokasi (opsional).
  final String? glong;

  /// Mengonversi DTO ke Map JSON untuk dikirim melalui HTTP POST client.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (text != null) 'text': text,
      if (feedFile != null) 'feed_file': feedFile,
      if (photos != null) 'photos': photos,
      if (feedType != null) 'feed_type': feedType,
      if (eventLocation != null) 'event_location': eventLocation,
      if (glat != null) 'glat': glat,
      if (glong != null) 'glong': glong,
    };
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
      ];
}
