import 'package:kawalo_mobile/core/utils/app_sanitizer.dart';
import 'package:kawalo_mobile/features/operational/data/models/operational_local_model.dart';
import 'package:kawalo_mobile/features/operational/data/models/operational_model.dart';

/// Mapper yang bertanggung jawab atas translasi data antara
/// [OperationalModel] / [DutyTimelineModel] (Data Layer DTO) dan
/// [OperationalLocalModel] / [DutyTimelineLocalModel] (Isar Database Cache)
/// dengan Anti-Corruption Layer (ACL) sanitasi tanpa fallback perusak data.
abstract final class OperationalLocalMapper {
  /// Mengonversi [DutyTimelineModel] DTO menjadi [DutyTimelineLocalModel] Isar
  /// dengan sanitasi data. Mengembalikan `null` jika ID tidak valid.
  static DutyTimelineLocalModel? toDutyTimelineLocal(DutyTimelineModel model) {
    return DutyTimelineLocalModel()
      ..id = AppSanitizer.cleanString(model.id) ?? model.id.trim()
      ..journeyUid = AppSanitizer.cleanString(model.journeyUid)
      ..duty = AppSanitizer.cleanString(model.duty)
      ..state = AppSanitizer.cleanString(model.state)
      ..dutyDt = AppSanitizer.cleanDate(model.dutyDt)
      ..stateDt = AppSanitizer.cleanDate(model.stateDt);
  }

  /// Mengonversi [DutyTimelineLocalModel] Isar menjadi [DutyTimelineModel] DTO
  /// dengan sanitasi data. Mengembalikan `null` jika ID tidak valid.
  static DutyTimelineModel? fromDutyTimelineLocal(
    DutyTimelineLocalModel local,
  ) {
    return DutyTimelineModel(
      id: AppSanitizer.cleanString(local.id) ?? local.id.trim(),
      journeyUid: AppSanitizer.cleanString(local.journeyUid),
      duty: AppSanitizer.cleanString(local.duty),
      state: AppSanitizer.cleanString(local.state),
      dutyDt: AppSanitizer.cleanDate(local.dutyDt),
      stateDt: AppSanitizer.cleanDate(local.stateDt),
    );
  }

  /// Mengonversi satu instance [OperationalModel] menjadi
  /// [OperationalLocalModel] untuk disimpan ke Isar database dengan sanitasi.
  /// Mengembalikan `null` jika email tidak valid.
  static OperationalLocalModel? toLocal(OperationalModel model) {
    final cleanedEmail =
        AppSanitizer.cleanEmail(model.userEmail) ?? model.userEmail.trim();

    final cleanedDate = AppSanitizer.cleanDate(model.dutyDate);
    final cleanedId = AppSanitizer.cleanString(model.id) ?? model.id.trim();

    final timelineTokens = model.timeline
        .map((t) => '${t.duty ?? ''} ${t.state ?? ''}')
        .where((s) => s.trim().isNotEmpty)
        .join(' ');
    final searchTokens = [
      model.userName,
      cleanedEmail,
      model.latestDuty,
      model.latestState,
      timelineTokens,
    ].where((s) => s != null && s.trim().isNotEmpty).join(' ');

    return OperationalLocalModel()
      ..id = cleanedId
      ..searchTokens = searchTokens
      ..userEmail = cleanedEmail
      ..totalActivities =
          AppSanitizer.cleanInteger(model.totalActivities) ??
          model.totalActivities
      ..userName = AppSanitizer.cleanString(model.userName)
      ..userProfilePic = AppSanitizer.cleanString(model.userProfilePic)
      ..groupName = AppSanitizer.cleanString(model.groupName)
      ..latestDuty = AppSanitizer.cleanString(model.latestDuty)
      ..latestState = AppSanitizer.cleanString(model.latestState)
      ..latestDutyDt = AppSanitizer.cleanDate(model.latestDutyDt)
      ..latestStateDt = AppSanitizer.cleanDate(model.latestStateDt)
      ..dutyDate = cleanedDate
      ..timeline = model.timeline
          .map(toDutyTimelineLocal)
          .whereType<DutyTimelineLocalModel>()
          .toList(growable: false);
  }

  /// Mengonversi satu instance [OperationalLocalModel] dari Isar database
  /// menjadi [OperationalModel] dengan sanitasi data. Mengembalikan `null`
  /// jika email tidak valid.
  static OperationalModel? fromLocal(OperationalLocalModel local) {
    return OperationalModel(
      id: AppSanitizer.cleanString(local.id) ?? local.id.trim(),
      userEmail:
          AppSanitizer.cleanEmail(local.userEmail) ?? local.userEmail.trim(),
      totalActivities:
          AppSanitizer.cleanInteger(local.totalActivities) ??
          local.totalActivities,
      userName: AppSanitizer.cleanString(local.userName),
      userProfilePic: AppSanitizer.cleanString(local.userProfilePic),
      groupName: AppSanitizer.cleanString(local.groupName),
      latestDuty: AppSanitizer.cleanString(local.latestDuty),
      latestState: AppSanitizer.cleanString(local.latestState),
      latestDutyDt: AppSanitizer.cleanDate(local.latestDutyDt),
      latestStateDt: AppSanitizer.cleanDate(local.latestStateDt),
      dutyDate: AppSanitizer.cleanDate(local.dutyDate),
      timeline: local.timeline
          .map(fromDutyTimelineLocal)
          .whereType<DutyTimelineModel>()
          .toList(growable: false),
    );
  }

  /// Mengonversi daftar [OperationalModel] menjadi daftar
  /// [OperationalLocalModel].
  static List<OperationalLocalModel> toLocalList(
    List<OperationalModel> models,
  ) {
    return models
        .map(toLocal)
        .whereType<OperationalLocalModel>()
        .toList(growable: false);
  }

  /// Mengonversi daftar [OperationalLocalModel] menjadi daftar
  /// [OperationalModel].
  static List<OperationalModel> fromLocalList(
    List<OperationalLocalModel> locals,
  ) {
    return locals
        .map(fromLocal)
        .whereType<OperationalModel>()
        .toList(growable: false);
  }
}
