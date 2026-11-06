import 'package:kawalo_mobile/core/utils/app_sanitizer.dart';
import 'package:kawalo_mobile/features/information/data/models/information_local_model.dart';
import 'package:kawalo_mobile/features/information/data/models/information_model.dart';

/// Mapper yang bertanggung jawab atas translasi data antara
/// [InformationModel] (Data Layer DTO) dan [InformationLocalModel] (Isar
/// Database Cache) dengan Anti-Corruption Layer (ACL) sanitasi.
abstract final class InformationLocalMapper {
  /// Mengonversi satu instance [InformationModel] menjadi
  /// [InformationLocalModel] untuk disimpan ke Isar database dengan sanitasi
  /// data tanpa fallback.
  static InformationLocalModel toLocal(InformationModel model) {
    return InformationLocalModel()
      ..id = AppSanitizer.cleanString(model.id) ?? model.id.trim()
      ..photos = AppSanitizer.cleanStringList(model.photos)
      ..title = AppSanitizer.cleanString(model.title)
      ..text = AppSanitizer.cleanString(model.text)
      ..userEmail = AppSanitizer.cleanEmail(model.userEmail)
      ..userName = AppSanitizer.cleanString(model.userName)
      ..userProfilePic = AppSanitizer.cleanString(model.userProfilePic)
      ..feedDt = AppSanitizer.cleanDate(model.feedDt)
      ..feedFile = AppSanitizer.cleanString(model.feedFile)
      ..feedType = AppSanitizer.cleanString(model.feedType)
      ..groupName = AppSanitizer.cleanString(model.groupName)
      ..eventLocation = AppSanitizer.cleanString(model.eventLocation)
      ..eventStartDt = AppSanitizer.cleanDate(model.eventStartDt)
      ..eventEndDt = AppSanitizer.cleanDate(model.eventEndDt)
      ..eventDuration = AppSanitizer.cleanInteger(model.eventDuration)
      ..glat = AppSanitizer.cleanLatitude(model.glat)
      ..glong = AppSanitizer.cleanLongitude(model.glong);
  }

  /// Mengonversi satu instance [InformationLocalModel] dari Isar database
  /// menjadi [InformationModel] dengan sanitasi data tanpa fallback.
  static InformationModel fromLocal(InformationLocalModel local) {
    return InformationModel(
      id: AppSanitizer.cleanString(local.id) ?? local.id.trim(),
      photos: AppSanitizer.cleanStringList(local.photos),
      title: AppSanitizer.cleanString(local.title),
      text: AppSanitizer.cleanString(local.text),
      userEmail: AppSanitizer.cleanEmail(local.userEmail),
      userName: AppSanitizer.cleanString(local.userName),
      userProfilePic: AppSanitizer.cleanString(local.userProfilePic),
      feedDt: AppSanitizer.cleanDate(local.feedDt),
      feedFile: AppSanitizer.cleanString(local.feedFile),
      feedType: AppSanitizer.cleanString(local.feedType),
      groupName: AppSanitizer.cleanString(local.groupName),
      eventLocation: AppSanitizer.cleanString(local.eventLocation),
      eventStartDt: AppSanitizer.cleanDate(local.eventStartDt),
      eventEndDt: AppSanitizer.cleanDate(local.eventEndDt),
      eventDuration: AppSanitizer.cleanInteger(local.eventDuration),
      glat: AppSanitizer.cleanLatitude(local.glat),
      glong: AppSanitizer.cleanLongitude(local.glong),
    );
  }

  /// Mengonversi daftar [InformationModel] menjadi daftar
  /// [InformationLocalModel].
  static List<InformationLocalModel> toLocalList(
    List<InformationModel> models,
  ) {
    return models.map(toLocal).toList(growable: false);
  }

  /// Mengonversi daftar [InformationLocalModel] menjadi daftar
  /// [InformationModel].
  static List<InformationModel> fromLocalList(
    List<InformationLocalModel> locals,
  ) {
    return locals.map(fromLocal).toList(growable: false);
  }
}
