import 'package:isar_community/isar.dart';

part 'incident_local_model.g.dart';

/// Skema tabel lokal Isar untuk cache daftar insiden (hanya daftar; detail,
/// balasan, dan stream SSE tidak disimpan).
@collection
class IncidentLocalModel {
  /// Primary key internal Isar.
  Id isarId = Isar.autoIncrement;

  /// Identifier unik insiden.
  @Index(unique: true, replace: true)
  late String id;

  /// ID grup tempat insiden terjadi; cache hanya dibaca untuk grup aktif.
  @Index()
  late String groupId;

  /// Judul laporan insiden.
  late String title;

  /// Penjelasan detail insiden.
  String? description;

  /// Kategori insiden (string wire API).
  String? category;

  /// Titik garis lintang GPS.
  double? glat;

  /// Titik garis bujur GPS.
  double? glong;

  /// Daftar URL foto bukti.
  late List<String> photos;

  /// Status siklus hidup insiden ('OPEN', 'RESOLVED').
  @Index()
  late String status;

  /// ID pengguna pelapor.
  late String createdBy;

  /// Nama pengguna pelapor.
  String? createdByName;

  /// ID pengguna yang menyelesaikan.
  String? resolvedBy;

  /// Nama pengguna yang menyelesaikan.
  String? resolvedByName;

  /// Timestamp penyelesaian (ISO 8601).
  String? resolvedAt;

  /// Timestamp soft-delete (ISO 8601).
  String? deletedAt;

  /// Waktu pembuatan dalam ISO 8601 UTC. Dinormalisasi ke UTC agar urutan dan
  /// perbandingan leksikografis untuk rentang tanggal & retensi akurat.
  @Index()
  late String createdAt;

  /// Timestamp pembaruan terakhir (ISO 8601).
  String? updatedAt;
}
