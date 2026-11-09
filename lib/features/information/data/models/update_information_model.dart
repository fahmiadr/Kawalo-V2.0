import 'package:equatable/equatable.dart';

/// Pure DTO model untuk payload pembaruan data informasi
/// (`UpdateInformationDto`).
///
/// Digunakan untuk serialisasi HTTP PUT/PATCH `/v1/information/:id`.
/// Dilarang keras mengimpor Domain Entity ke dalam file ini.
class UpdateInformationModel extends Equatable {
  /// Membuat instance [UpdateInformationModel].
  const UpdateInformationModel({
    this.title,
    this.text,
    this.feedFile,
    this.photos,
    this.feedType,
    this.eventLocation,
    this.glat,
    this.glong,
    this.includeNulls = false,
  });

  /// Judul informasi baru (opsional).
  final String? title;

  /// Isi teks informasi baru (opsional).
  final String? text;

  /// Berkas lampiran feed URL baru (opsional).
  final String? feedFile;

  /// Daftar URL/nama foto baru (opsional, maksimal 4 item).
  final List<String>? photos;

  /// Tipe kategori informasi baru (opsional).
  final String? feedType;

  /// Lokasi acara/kegiatan baru (opsional).
  final String? eventLocation;

  /// Garis lintang lokasi baru (opsional).
  final String? glat;

  /// Garis bujur lokasi baru (opsional).
  final String? glong;

  /// Menandakan apakah field opsional dengan nilai `null` tetap disertakan
  /// dalam JSON untuk mengosongkan nilai di backend server.
  final bool includeNulls;

  /// Mengonversi DTO ke Map JSON untuk dikirim melalui HTTP PUT/PATCH client.
  Map<String, dynamic> toJson() {
    if (includeNulls) {
      return {
        if (title != null) 'title': title,
        'text': text,
        'feed_file': feedFile,
        if (photos != null) 'photos': photos,
        if (feedType != null) 'feed_type': feedType,
        'event_location': eventLocation,
        'glat': glat,
        'glong': glong,
      };
    }
    return {
      if (title != null) 'title': title,
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
    includeNulls,
  ];
}
