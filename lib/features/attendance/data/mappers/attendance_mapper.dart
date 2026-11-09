import 'package:kawalo_mobile/core/utils/app_sanitizer.dart';
import 'package:kawalo_mobile/features/attendance/data/models/attendance_model.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';

/// Mapper yang bertanggung jawab atas translasi data antara
/// [AttendanceModel] (Data Layer DTO) dan [AttendanceItemEntity] (Domain
/// Layer Entity).
///
/// Mengikuti pola Dedicated Mapper yang selaras dengan backend API
/// (`AttendanceResponseMapper`) dengan Anti-Corruption Layer (ACL) sanitasi.
abstract final class AttendanceMapper {
  /// Mengonversi satu instance [AttendanceModel] menjadi
  /// [AttendanceItemEntity] dengan sanitasi data.
  static AttendanceItemEntity toEntity(AttendanceModel model) {
    return AttendanceItemEntity(
      id: AppSanitizer.cleanString(model.id) ?? model.id.trim(),
      category:
          AppSanitizer.cleanString(model.category) ?? model.category.trim(),
      diffMinutes:
          AppSanitizer.cleanInteger(model.diffMinutes) ?? model.diffMinutes,
      userEmail: AppSanitizer.cleanEmail(model.userEmail),
      userName: AppSanitizer.cleanString(model.userName),
      userProfilePic: AppSanitizer.cleanString(model.userProfilePic),
      userDuty: AppSanitizer.cleanString(model.userDuty),
      attendanceDt: AppSanitizer.cleanDate(model.attendanceDt),
      attendanceType: AppSanitizer.cleanString(model.attendanceType),
      locationName: AppSanitizer.cleanString(model.locationName),
      latitude: AppSanitizer.cleanLatitudeDouble(model.latitude),
      longitude: AppSanitizer.cleanLongitudeDouble(model.longitude),
      shiftName: AppSanitizer.cleanString(model.shiftName),
      shiftColor: AppSanitizer.cleanString(model.shiftColor),
      shiftTimeWindow: AppSanitizer.cleanTimeWindow(model.shiftTimeWindow),
      groupName: AppSanitizer.cleanString(model.groupName),
    );
  }

  /// Mengonversi daftar [AttendanceModel] menjadi daftar
  /// [AttendanceItemEntity].
  static List<AttendanceItemEntity> toEntityList(List<AttendanceModel> models) {
    return models.map(toEntity).toList(growable: false);
  }
}
