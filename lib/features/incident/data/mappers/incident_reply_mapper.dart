import 'dart:convert';

import 'package:kawalo_mobile/core/network/sse_stream_transformer.dart';
import 'package:kawalo_mobile/core/utils/app_sanitizer.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_reply_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/post_incident_reply_model.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_reply_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_stream_event.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/post_incident_reply_data.dart';

/// Mapper yang bertanggung jawab atas translasi pesan balasan dan event
/// realtime SSE ke dalam entitas domain [IncidentReplyEntity] dan
/// [IncidentStreamEvent].
abstract final class IncidentReplyMapper {
  /// Mengonversi [IncidentReplyModel] DTO menjadi [IncidentReplyEntity].
  static IncidentReplyEntity toEntity(IncidentReplyModel model) {
    final createdAtDate = DateTime.tryParse(model.createdAt) ?? DateTime.now();

    return IncidentReplyEntity(
      id: AppSanitizer.cleanString(model.id) ?? model.id.trim(),
      incidentId:
          AppSanitizer.cleanString(model.incidentId) ?? model.incidentId.trim(),
      senderId:
          AppSanitizer.cleanString(model.senderId) ?? model.senderId.trim(),
      senderName: AppSanitizer.cleanString(model.senderName) ?? 'Pengguna',
      senderRole:
          AppSanitizer.cleanRole(model.senderRole) ?? model.senderRole.trim(),
      message: AppSanitizer.cleanString(model.message) ?? model.message.trim(),
      photos: AppSanitizer.cleanStringList(model.photos),
      createdAt: createdAtDate,
    );
  }

  /// Mengonversi daftar [IncidentReplyModel] menjadi [IncidentReplyEntity].
  static List<IncidentReplyEntity> toEntityList(
    List<IncidentReplyModel> models,
  ) {
    return models.map(toEntity).toList(growable: false);
  }

  /// Mengonversi [PostIncidentReplyData] domain ke
  /// [PostIncidentReplyModel] DTO.
  static PostIncidentReplyModel toPostModel(PostIncidentReplyData data) {
    return PostIncidentReplyModel(
      message: data.message.trim(),
      photos: data.photos,
    );
  }

  /// Mengurai [SseMessage] wire stream menjadi [IncidentStreamEvent] domain.
  ///
  /// Mengembalikan `null` jika payload tidak valid atau bukan event yang
  /// dikenali.
  static IncidentStreamEvent? parseSseMessage(SseMessage message) {
    final eventType = message.event?.trim();
    final dataString = message.data.trim();
    if (dataString.isEmpty) return null;

    final dynamic decoded;
    try {
      decoded = jsonDecode(dataString);
    } on Object catch (_) {
      return null;
    }

    if (decoded is! Map<String, dynamic>) return null;

    switch (eventType) {
      case 'new_reply':
        final replyModel = IncidentReplyModel.fromJson(decoded);
        return IncidentReplyStreamEvent(toEntity(replyModel));

      case 'thread_resolved':
        final incidentId = (decoded['incident_id'] ?? '') as String;
        final resolvedBy = (decoded['resolved_by'] ?? '') as String;
        final resolvedByName =
            (decoded['resolved_by_name'] ?? 'Rekan') as String;
        final rawResolvedAt = decoded['resolved_at'];
        final resolvedAt = rawResolvedAt != null
            ? (DateTime.tryParse(rawResolvedAt.toString()) ?? DateTime.now())
            : DateTime.now();

        return IncidentResolvedStreamEvent(
          incidentId: incidentId,
          resolvedBy: resolvedBy,
          resolvedByName: resolvedByName,
          resolvedAt: resolvedAt,
        );

      case 'incident_deleted':
        final incidentId = (decoded['incident_id'] ?? '') as String;
        final rawDeletedAt = decoded['deleted_at'];
        final deletedAt = rawDeletedAt != null
            ? (DateTime.tryParse(rawDeletedAt.toString()) ?? DateTime.now())
            : DateTime.now();

        return IncidentDeletedStreamEvent(
          incidentId: incidentId,
          deletedAt: deletedAt,
        );

      default:
        return null;
    }
  }
}
