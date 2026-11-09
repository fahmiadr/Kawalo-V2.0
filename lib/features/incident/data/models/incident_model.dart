import 'package:equatable/equatable.dart';

/// Pure DTO model untuk pertukaran data JSON laporan insiden dengan API
/// (`IncidentDto`).
///
/// Dilarang keras mengimpor Domain Entity ke dalam file ini.
class IncidentModel extends Equatable {
  /// Membuat instance [IncidentModel].
  const IncidentModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.createdByName,
    this.description,
    this.category,
    this.glat,
    this.glong,
    this.photos = const [],
    this.resolvedBy,
    this.resolvedByName,
    this.resolvedAt,
    this.deletedAt,
    this.updatedAt,
  });

  /// Mengonversi JSON Map dari backend menjadi objek [IncidentModel].
  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json['id'] as String,
      groupId: (json['group_id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      status: (json['status'] ?? 'OPEN') as String,
      createdBy: (json['created_by'] ?? '') as String,
      createdByName: json['created_by_name'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      glat: json['glat'] != null ? (json['glat'] as num).toDouble() : null,
      glong: json['glong'] != null ? (json['glong'] as num).toDouble() : null,
      photos: json['photos'] != null
          ? (json['photos'] as List<dynamic>).map((e) => e.toString()).toList()
          : const [],
      resolvedBy: json['resolved_by'] as String?,
      resolvedByName: json['resolved_by_name'] as String?,
      resolvedAt: json['resolved_at'] as String?,
      deletedAt: json['deleted_at'] as String?,
      createdAt:
          (json['created_at'] ?? DateTime.now().toIso8601String()) as String,
      updatedAt: json['updated_at'] as String?,
    );
  }

  /// ID unik insiden.
  final String id;

  /// ID grup insiden.
  final String groupId;

  /// Judul laporan insiden.
  final String title;

  /// Penjelasan detail insiden.
  final String? description;

  /// Kategori insiden (string wire API).
  final String? category;

  /// Titik garis lintang GPS.
  final double? glat;

  /// Titik garis bujur GPS.
  final double? glong;

  /// Daftar URL foto bukti.
  final List<String> photos;

  /// Status siklus hidup insiden ('OPEN', 'RESOLVED').
  final String status;

  /// ID pengguna pelapor.
  final String createdBy;

  /// Nama pengguna pelapor.
  final String? createdByName;

  /// ID pengguna yang menyelesaikan.
  final String? resolvedBy;

  /// Nama pengguna yang menyelesaikan.
  final String? resolvedByName;

  /// ISO 8601 timestamp penyelesaian insiden.
  final String? resolvedAt;

  /// ISO 8601 timestamp soft-delete insiden.
  final String? deletedAt;

  /// ISO 8601 timestamp pembuatan laporan insiden.
  final String createdAt;

  /// ISO 8601 timestamp pembaruan data insiden terakhir.
  final String? updatedAt;

  /// Mengonversi objek ke Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (glat != null) 'glat': glat,
      if (glong != null) 'glong': glong,
      'photos': photos,
      'status': status,
      'created_by': createdBy,
      if (createdByName != null) 'created_by_name': createdByName,
      if (resolvedBy != null) 'resolved_by': resolvedBy,
      if (resolvedByName != null) 'resolved_by_name': resolvedByName,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        title,
        description,
        category,
        glat,
        glong,
        photos,
        status,
        createdBy,
        createdByName,
        resolvedBy,
        resolvedByName,
        resolvedAt,
        deletedAt,
        createdAt,
        updatedAt,
      ];
}
