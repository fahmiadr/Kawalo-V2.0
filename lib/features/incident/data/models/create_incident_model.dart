import 'package:equatable/equatable.dart';

/// Pure DTO model untuk payload pembuatan laporan insiden baru
/// (`CreateIncidentDto`).
///
/// Dilarang keras mengimpor Domain Entity ke dalam file ini.
class CreateIncidentModel extends Equatable {
  /// Membuat instance [CreateIncidentModel].
  const CreateIncidentModel({
    required this.title,
    required this.groupId,
    this.description,
    this.category,
    this.glat,
    this.glong,
    this.photos = const [],
  });

  /// Judul insiden.
  final String title;

  /// ID grup tempat insiden dilaporkan.
  final String groupId;

  /// Penjelasan detail insiden.
  final String? description;

  /// Kategori insiden (string wire API).
  final String? category;

  /// Titik garis lintang GPS.
  final double? glat;

  /// Titik garis bujur GPS.
  final double? glong;

  /// Daftar URL foto bukti yang dikirimkan langsung sebagai array string URL.
  final List<String> photos;

  /// Mengonversi ke Map JSON untuk dikirimkan via HTTP POST.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'group_id': groupId,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (glat != null) 'glat': glat,
      if (glong != null) 'glong': glong,
      'photos': photos,
    };
  }

  @override
  List<Object?> get props => [
    title,
    groupId,
    description,
    category,
    glat,
    glong,
    photos,
  ];
}
