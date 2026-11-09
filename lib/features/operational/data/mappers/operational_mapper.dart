import 'package:kawalo_mobile/core/utils/app_sanitizer.dart';
import 'package:kawalo_mobile/features/operational/data/models/operational_model.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';

/// Mapper yang bertanggung jawab atas translasi data antara
/// [OperationalModel] / [DutyTimelineModel] (Data Layer DTO) dan
/// [OperationalItemEntity] / [DutyTimelineEntity] (Domain Layer Entity).
///
/// Mengikuti pola Dedicated Mapper yang selaras dengan backend API
/// (`OperationalResponseMapper`) dengan Anti-Corruption Layer (ACL) sanitasi.
abstract final class OperationalMapper {
  /// Mengonversi [DutyTimelineModel] DTO ke [DutyTimelineEntity] Domain
  /// dengan sanitasi data.
  static DutyTimelineEntity toDutyTimelineEntity(DutyTimelineModel model) {
    return DutyTimelineEntity(
      id: AppSanitizer.cleanString(model.id) ?? model.id.trim(),
      journeyUid: AppSanitizer.cleanString(model.journeyUid),
      duty: AppSanitizer.cleanString(model.duty),
      state: AppSanitizer.cleanString(model.state),
      dutyDt: AppSanitizer.cleanDate(model.dutyDt),
      stateDt: AppSanitizer.cleanDate(model.stateDt),
    );
  }

  /// Mengonversi [OperationalModel] DTO ke [OperationalItemEntity]
  /// Domain dengan sanitasi data penuh (Anti-Corruption Layer).
  static OperationalItemEntity toEntity(OperationalModel model) {
    return OperationalItemEntity(
      id: AppSanitizer.cleanString(model.id) ?? model.id.trim(),
      userEmail:
          AppSanitizer.cleanEmail(model.userEmail) ?? model.userEmail.trim(),
      totalActivities:
          AppSanitizer.cleanInteger(model.totalActivities) ??
          model.totalActivities,
      userName: AppSanitizer.cleanString(model.userName),
      userProfilePic: AppSanitizer.cleanString(model.userProfilePic),
      groupName: AppSanitizer.cleanString(model.groupName),
      latestDuty: AppSanitizer.cleanString(model.latestDuty),
      latestState: AppSanitizer.cleanString(model.latestState),
      latestDutyDt: AppSanitizer.cleanDate(model.latestDutyDt),
      latestStateDt: AppSanitizer.cleanDate(model.latestStateDt),
      dutyDate: AppSanitizer.cleanDate(model.dutyDate),
      timeline: model.timeline
          .map(toDutyTimelineEntity)
          .toList(growable: false),
    );
  }

  /// Mengonversi daftar [OperationalModel] menjadi daftar
  /// [OperationalItemEntity].
  static List<OperationalItemEntity> toEntityList(
    List<OperationalModel> models,
  ) {
    return models.map(toEntity).toList(growable: false);
  }
}
