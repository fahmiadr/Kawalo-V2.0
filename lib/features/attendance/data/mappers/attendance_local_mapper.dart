import 'package:kawalo_mobile/core/utils/app_sanitizer.dart';
import 'package:kawalo_mobile/features/attendance/data/models/attendance_local_model.dart';
import 'package:kawalo_mobile/features/attendance/data/models/attendance_model.dart';

/// Mapper yang bertanggung jawab atas translasi data antara
/// [AttendanceModel] (Data Layer DTO) dan [AttendanceLocalModel] (Isar
/// Database Cache) dengan Anti-Corruption Layer (ACL) sanitasi.
abstract final class AttendanceLocalMapper {
  /// Mengonversi satu instance [AttendanceModel] menjadi
  /// [AttendanceLocalModel] untuk disimpan ke Isar database dengan sanitasi
  /// data.
  static AttendanceLocalModel toLocal(AttendanceModel model) {
    return AttendanceLocalModel()
      ..id = AppSanitizer.cleanString(model.id) ?? model.id.trim()
      ..category =
          AppSanitizer.cleanString(model.category) ?? model.category.trim()
      ..diffMinutes =
          AppSanitizer.cleanInteger(model.diffMinutes) ?? model.diffMinutes
      ..userEmail = AppSanitizer.cleanEmail(model.userEmail)
      ..userName = AppSanitizer.cleanString(model.userName)
      ..userProfilePic = AppSanitizer.cleanString(model.userProfilePic)
      ..userDuty = AppSanitizer.cleanString(model.userDuty)
      ..attendanceDt = AppSanitizer.cleanDate(model.attendanceDt)
      ..attendanceType = AppSanitizer.cleanString(model.attendanceType)
      ..latitude = AppSanitizer.cleanLatitude(model.latitude)
      ..longitude = AppSanitizer.cleanLongitude(model.longitude)
      ..locationName = AppSanitizer.cleanString(model.locationName)
      ..shiftName = AppSanitizer.cleanString(model.shiftName)
      ..shiftColor = AppSanitizer.cleanString(model.shiftColor)
      ..shiftTimeWindow = AppSanitizer.cleanTimeWindow(model.shiftTimeWindow)
      ..groupName = AppSanitizer.cleanString(model.groupName);
  }

  /// Mengonversi satu instance [AttendanceLocalModel] dari Isar database
  /// menjadi [AttendanceModel] dengan sanitasi data.
  static AttendanceModel fromLocal(AttendanceLocalModel local) {
    return AttendanceModel(
      id: AppSanitizer.cleanString(local.id) ?? local.id.trim(),
      category:
          AppSanitizer.cleanString(local.category) ?? local.category.trim(),
      diffMinutes:
          AppSanitizer.cleanInteger(local.diffMinutes) ?? local.diffMinutes,
      userEmail: AppSanitizer.cleanEmail(local.userEmail),
      userName: AppSanitizer.cleanString(local.userName),
      userProfilePic: AppSanitizer.cleanString(local.userProfilePic),
      userDuty: AppSanitizer.cleanString(local.userDuty),
      attendanceDt: AppSanitizer.cleanDate(local.attendanceDt),
      attendanceType: AppSanitizer.cleanString(local.attendanceType),
      latitude: AppSanitizer.cleanLatitude(local.latitude),
      longitude: AppSanitizer.cleanLongitude(local.longitude),
      locationName: AppSanitizer.cleanString(local.locationName),
      shiftName: AppSanitizer.cleanString(local.shiftName),
      shiftColor: AppSanitizer.cleanString(local.shiftColor),
      shiftTimeWindow: AppSanitizer.cleanTimeWindow(local.shiftTimeWindow),
      groupName: AppSanitizer.cleanString(local.groupName),
    );
  }

  /// Mengonversi daftar [AttendanceModel] menjadi daftar
  /// [AttendanceLocalModel].
  static List<AttendanceLocalModel> toLocalList(List<AttendanceModel> models) {
    return models.map(toLocal).toList(growable: false);
  }

  /// Mengonversi daftar [AttendanceLocalModel] menjadi daftar
  /// [AttendanceModel].
  static List<AttendanceModel> fromLocalList(
    List<AttendanceLocalModel> locals,
  ) {
    return locals.map(fromLocal).toList(growable: false);
  }
}
