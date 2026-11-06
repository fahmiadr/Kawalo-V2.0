import 'package:kawalo_mobile/core/utils/app_sanitizer.dart';
import 'package:kawalo_mobile/features/incident/data/mappers/incident_reply_mapper.dart';
import 'package:kawalo_mobile/features/incident/data/models/create_incident_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_detail_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_query_model.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/create_incident_data.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_category.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_detail_result.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_query_params.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';

/// Mapper yang bertanggung jawab atas translasi data antara model DTO Insiden
/// dan Domain Entities/Value Objects dengan Anti-Corruption Layer (ACL).
abstract final class IncidentMapper {
  /// Mengonversi [IncidentModel] DTO menjadi [IncidentEntity] domain.
  static IncidentEntity toEntity(IncidentModel model) {
    final createdAtDate = DateTime.tryParse(model.createdAt) ?? DateTime.now();
    final updatedAtDate =
        model.updatedAt != null ? DateTime.tryParse(model.updatedAt!) : null;
    final resolvedAtDate =
        model.resolvedAt != null ? DateTime.tryParse(model.resolvedAt!) : null;
    final deletedAtDate =
        model.deletedAt != null ? DateTime.tryParse(model.deletedAt!) : null;

    return IncidentEntity(
      id: AppSanitizer.cleanString(model.id) ?? model.id.trim(),
      groupId: AppSanitizer.cleanString(model.groupId) ?? model.groupId.trim(),
      title: AppSanitizer.cleanString(model.title) ?? model.title.trim(),
      description: AppSanitizer.cleanString(model.description),
      category: IncidentCategory.fromString(model.category),
      glat: model.glat,
      glong: model.glong,
      photos: AppSanitizer.cleanStringList(model.photos),
      status: IncidentStatus.fromString(model.status),
      createdBy:
          AppSanitizer.cleanString(model.createdBy) ?? model.createdBy.trim(),
      createdByName: AppSanitizer.cleanString(model.createdByName),
      resolvedBy: AppSanitizer.cleanString(model.resolvedBy),
      resolvedByName: AppSanitizer.cleanString(model.resolvedByName),
      resolvedAt: resolvedAtDate,
      deletedAt: deletedAtDate,
      createdAt: createdAtDate,
      updatedAt: updatedAtDate,
    );
  }

  /// Mengonversi daftar [IncidentModel] menjadi daftar [IncidentEntity].
  static List<IncidentEntity> toEntityList(List<IncidentModel> models) {
    return models.map(toEntity).toList(growable: false);
  }

  /// Mengonversi [IncidentDetailModel] menjadi [IncidentDetailResult].
  static IncidentDetailResult toDetailResult(IncidentDetailModel model) {
    return IncidentDetailResult(
      incident: toEntity(model.incident),
      replies: IncidentReplyMapper.toEntityList(model.replies),
    );
  }

  /// Mengonversi domain [CreateIncidentData] ke [CreateIncidentModel] DTO.
  static CreateIncidentModel toCreateModel(CreateIncidentData data) {
    return CreateIncidentModel(
      title: data.title.trim(),
      groupId: data.groupId.trim(),
      description: AppSanitizer.cleanString(data.description),
      category: data.category?.value,
      glat: data.glat,
      glong: data.glong,
      photos: data.photos,
    );
  }

  /// Mengonversi domain [IncidentQueryParams] ke [IncidentQueryModel] DTO.
  static IncidentQueryModel toQueryModel(IncidentQueryParams params) {
    return IncidentQueryModel(
      groupId: params.groupId?.trim(),
      status: params.status?.value,
      search: params.search?.trim(),
      startDate: params.startDate,
      endDate: params.endDate,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
