// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incident_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IncidentModel _$IncidentModelFromJson(Map<String, dynamic> json) =>
    IncidentModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'OPEN',
      createdBy: json['created_by'] as String? ?? '',
      createdAt: _createdAtOrNow(json['created_at']),
      createdByName: json['created_by_name'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      glat: (json['glat'] as num?)?.toDouble(),
      glong: (json['glong'] as num?)?.toDouble(),
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      resolvedBy: json['resolved_by'] as String?,
      resolvedByName: json['resolved_by_name'] as String?,
      resolvedAt: json['resolved_at'] as String?,
      deletedAt: json['deleted_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$IncidentModelToJson(IncidentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group_id': instance.groupId,
      'title': instance.title,
      'description': ?instance.description,
      'category': ?instance.category,
      'glat': ?instance.glat,
      'glong': ?instance.glong,
      'photos': instance.photos,
      'status': instance.status,
      'created_by': instance.createdBy,
      'created_by_name': ?instance.createdByName,
      'resolved_by': ?instance.resolvedBy,
      'resolved_by_name': ?instance.resolvedByName,
      'resolved_at': ?instance.resolvedAt,
      'deleted_at': ?instance.deletedAt,
      'created_at': instance.createdAt,
      'updated_at': ?instance.updatedAt,
    };
