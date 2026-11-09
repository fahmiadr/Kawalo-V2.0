import 'package:kawalo_mobile/core/utils/app_sanitizer.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_local_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_model.dart';

/// Mapper antara [IncidentModel] (DTO) dan [IncidentLocalModel] (cache Isar).
abstract final class IncidentLocalMapper {
  /// Normalizes an ISO 8601 timestamp to UTC so cached values compare
  /// lexicographically; unparsable input is returned unchanged.
  static String toUtcIso(String raw) =>
      DateTime.tryParse(raw)?.toUtc().toIso8601String() ?? raw;

  /// Mengonversi [IncidentModel] menjadi [IncidentLocalModel].
  static IncidentLocalModel toLocal(IncidentModel model) {
    return IncidentLocalModel()
      ..id = AppSanitizer.cleanString(model.id) ?? model.id.trim()
      ..groupId =
          AppSanitizer.cleanString(model.groupId) ?? model.groupId.trim()
      ..title = AppSanitizer.cleanString(model.title) ?? model.title.trim()
      ..description = AppSanitizer.cleanString(model.description)
      ..category = AppSanitizer.cleanString(model.category)
      ..glat = model.glat
      ..glong = model.glong
      ..photos = AppSanitizer.cleanStringList(model.photos).toList()
      ..status = AppSanitizer.cleanString(model.status) ?? model.status.trim()
      ..createdBy =
          AppSanitizer.cleanString(model.createdBy) ?? model.createdBy.trim()
      ..createdByName = AppSanitizer.cleanString(model.createdByName)
      ..resolvedBy = AppSanitizer.cleanString(model.resolvedBy)
      ..resolvedByName = AppSanitizer.cleanString(model.resolvedByName)
      ..resolvedAt = AppSanitizer.cleanString(model.resolvedAt)
      ..deletedAt = AppSanitizer.cleanString(model.deletedAt)
      ..createdAt = toUtcIso(model.createdAt)
      ..updatedAt = AppSanitizer.cleanString(model.updatedAt);
  }

  /// Mengonversi [IncidentLocalModel] menjadi [IncidentModel].
  static IncidentModel fromLocal(IncidentLocalModel local) {
    return IncidentModel(
      id: local.id,
      groupId: local.groupId,
      title: local.title,
      description: local.description,
      category: local.category,
      glat: local.glat,
      glong: local.glong,
      photos: List.of(local.photos),
      status: local.status,
      createdBy: local.createdBy,
      createdByName: local.createdByName,
      resolvedBy: local.resolvedBy,
      resolvedByName: local.resolvedByName,
      resolvedAt: local.resolvedAt,
      deletedAt: local.deletedAt,
      createdAt: local.createdAt,
      updatedAt: local.updatedAt,
    );
  }

  /// Mengonversi daftar [IncidentModel] menjadi daftar [IncidentLocalModel].
  static List<IncidentLocalModel> toLocalList(List<IncidentModel> models) {
    return models.map(toLocal).toList(growable: false);
  }

  /// Mengonversi daftar [IncidentLocalModel] menjadi daftar [IncidentModel].
  static List<IncidentModel> fromLocalList(List<IncidentLocalModel> locals) {
    return locals.map(fromLocal).toList(growable: false);
  }
}
