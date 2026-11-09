import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'incident_model.g.dart';

/// Server may omit `created_at`; fall back to the moment of parsing.
String _createdAtOrNow(Object? value) =>
    (value as String?) ?? DateTime.now().toIso8601String();

/// Pure DTO model untuk pertukaran data JSON laporan insiden dengan API
/// (`IncidentDto`).
///
/// Dilarang keras mengimpor Domain Entity ke dalam file ini.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class IncidentModel extends Equatable {
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

  factory IncidentModel.fromJson(Map<String, dynamic> json) =>
      _$IncidentModelFromJson(json);

  /// ID unik insiden.
  final String id;

  /// ID grup insiden.
  @JsonKey(defaultValue: '')
  final String groupId;

  /// Judul laporan insiden.
  @JsonKey(defaultValue: '')
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
  @JsonKey(defaultValue: <String>[])
  final List<String> photos;

  /// Status siklus hidup insiden ('OPEN', 'RESOLVED').
  @JsonKey(defaultValue: 'OPEN')
  final String status;

  /// ID pengguna pelapor.
  @JsonKey(defaultValue: '')
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
  @JsonKey(fromJson: _createdAtOrNow)
  final String createdAt;

  /// ISO 8601 timestamp pembaruan data insiden terakhir.
  final String? updatedAt;

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
