import 'package:kawalo_mobile/core/utils/app_sanitizer.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_local_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_model.dart';

/// Mapper yang bertanggung jawab atas translasi data antara
/// [GuestModel] (Data Layer DTO) dan [GuestLocalModel] (Isar Database Cache)
/// dengan Anti-Corruption Layer (ACL) sanitasi.
abstract final class GuestLocalMapper {
  /// Mengonversi satu instance [GuestModel] menjadi [GuestLocalModel] untuk
  /// disimpan ke Isar database dengan sanitasi data.
  static GuestLocalModel toLocal(GuestModel model) {
    return GuestLocalModel()
      ..id = AppSanitizer.cleanString(model.id) ?? model.id.trim()
      ..groupName = AppSanitizer.cleanString(model.groupName)
      ..guestName = AppSanitizer.cleanString(model.guestName)
      ..guestNumber = AppSanitizer.cleanString(model.guestNumber)
      ..guestIdentity = AppSanitizer.cleanString(model.guestIdentity)
      ..guestIdentityType = AppSanitizer.cleanString(model.guestIdentityType)
      ..guestPhoto = AppSanitizer.cleanString(model.guestPhoto)
      ..guestDt = AppSanitizer.cleanDate(model.guestDt)
      ..guestAckDt = AppSanitizer.cleanDate(model.guestAckDt)
      ..guestOutDt = AppSanitizer.cleanDate(model.guestOutDt)
      ..guestPurpose = AppSanitizer.cleanString(model.guestPurpose)
      ..guestDestination = AppSanitizer.cleanString(model.guestDestination)
      ..guestToUserEmail = AppSanitizer.cleanEmail(model.guestToUserEmail)
      ..guestToUserName = AppSanitizer.cleanString(model.guestToUserName)
      ..guestCreatorEmail = AppSanitizer.cleanEmail(model.guestCreatorEmail)
      ..guestCreatorName = AppSanitizer.cleanString(model.guestCreatorName)
      ..guestCategory = AppSanitizer.cleanString(model.guestCategory)
      ..qrUid = AppSanitizer.cleanString(model.qrUid)
      ..guestAddress = AppSanitizer.cleanString(model.guestAddress)
      ..guestType = AppSanitizer.cleanString(model.guestType)
      ..guestCheckoutByEmail =
          AppSanitizer.cleanEmail(model.guestCheckoutByEmail)
      ..guestCheckoutByName =
          AppSanitizer.cleanString(model.guestCheckoutByName);
  }

  /// Mengonversi satu instance [GuestLocalModel] dari Isar database menjadi
  /// [GuestModel] dengan sanitasi data.
  static GuestModel fromLocal(GuestLocalModel local) {
    return GuestModel(
      id: AppSanitizer.cleanString(local.id) ?? local.id.trim(),
      groupName: AppSanitizer.cleanString(local.groupName),
      guestName: AppSanitizer.cleanString(local.guestName),
      guestNumber: AppSanitizer.cleanString(local.guestNumber),
      guestIdentity: AppSanitizer.cleanString(local.guestIdentity),
      guestIdentityType: AppSanitizer.cleanString(local.guestIdentityType),
      guestPhoto: AppSanitizer.cleanString(local.guestPhoto),
      guestDt: AppSanitizer.cleanDate(local.guestDt),
      guestAckDt: AppSanitizer.cleanDate(local.guestAckDt),
      guestOutDt: AppSanitizer.cleanDate(local.guestOutDt),
      guestPurpose: AppSanitizer.cleanString(local.guestPurpose),
      guestDestination: AppSanitizer.cleanString(local.guestDestination),
      guestToUserEmail: AppSanitizer.cleanEmail(local.guestToUserEmail),
      guestToUserName: AppSanitizer.cleanString(local.guestToUserName),
      guestCreatorEmail: AppSanitizer.cleanEmail(local.guestCreatorEmail),
      guestCreatorName: AppSanitizer.cleanString(local.guestCreatorName),
      guestCategory: AppSanitizer.cleanString(local.guestCategory),
      qrUid: AppSanitizer.cleanString(local.qrUid),
      guestAddress: AppSanitizer.cleanString(local.guestAddress),
      guestType: AppSanitizer.cleanString(local.guestType),
      guestCheckoutByEmail:
          AppSanitizer.cleanEmail(local.guestCheckoutByEmail),
      guestCheckoutByName:
          AppSanitizer.cleanString(local.guestCheckoutByName),
    );
  }

  /// Mengonversi daftar [GuestModel] menjadi daftar [GuestLocalModel].
  static List<GuestLocalModel> toLocalList(List<GuestModel> models) {
    return models.map(toLocal).toList(growable: false);
  }

  /// Mengonversi daftar [GuestLocalModel] menjadi daftar [GuestModel].
  static List<GuestModel> fromLocalList(List<GuestLocalModel> locals) {
    return locals.map(fromLocal).toList(growable: false);
  }
}
