import 'package:kawalo_mobile/core/utils/app_sanitizer.dart';
import 'package:kawalo_mobile/features/guest/data/models/delete_batch_guest_response_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_model.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/delete_batch_result.dart';

/// Mapper yang bertanggung jawab atas translasi data antara
/// [GuestModel] (Data Layer DTO) dan [GuestItemEntity] (Domain Layer Entity).
///
/// Mengikuti pola Dedicated Mapper yang selaras dengan backend API
/// (`GuestResponseMapper`) dengan Anti-Corruption Layer (ACL) sanitasi.
abstract final class GuestMapper {
  /// Mengonversi satu instance [GuestModel] menjadi [GuestItemEntity] dengan
  /// sanitasi data.
  static GuestItemEntity toEntity(GuestModel model) {
    return GuestItemEntity(
      id: AppSanitizer.cleanString(model.id) ?? model.id.trim(),
      groupName: AppSanitizer.cleanString(model.groupName),
      guestName: AppSanitizer.cleanString(model.guestName),
      guestNumber: AppSanitizer.cleanString(model.guestNumber),
      guestIdentity: AppSanitizer.cleanString(model.guestIdentity),
      guestIdentityType: AppSanitizer.cleanString(model.guestIdentityType),
      guestPhoto: AppSanitizer.cleanString(model.guestPhoto),
      guestDt: AppSanitizer.cleanDate(model.guestDt),
      guestAckDt: AppSanitizer.cleanDate(model.guestAckDt),
      guestOutDt: AppSanitizer.cleanDate(model.guestOutDt),
      guestPurpose: AppSanitizer.cleanString(model.guestPurpose),
      guestDestination: AppSanitizer.cleanString(model.guestDestination),
      guestToUserEmail: AppSanitizer.cleanEmail(model.guestToUserEmail),
      guestToUserName: AppSanitizer.cleanString(model.guestToUserName),
      guestCreatorEmail: AppSanitizer.cleanEmail(model.guestCreatorEmail),
      guestCreatorName: AppSanitizer.cleanString(model.guestCreatorName),
      guestCategory: AppSanitizer.cleanString(model.guestCategory),
      qrUid: AppSanitizer.cleanString(model.qrUid),
      guestAddress: AppSanitizer.cleanString(model.guestAddress),
      guestType: AppSanitizer.cleanString(model.guestType),
      guestCheckoutByEmail:
          AppSanitizer.cleanEmail(model.guestCheckoutByEmail),
      guestCheckoutByName:
          AppSanitizer.cleanString(model.guestCheckoutByName),
    );
  }

  /// Mengonversi daftar [GuestModel] menjadi daftar [GuestItemEntity].
  static List<GuestItemEntity> toEntityList(List<GuestModel> models) {
    return models.map(toEntity).toList(growable: false);
  }

  /// Mengonversi [DeleteBatchGuestResponseModel] (DTO) menjadi
  /// [DeleteBatchResult] (Domain Response Model).
  static DeleteBatchResult toDeleteBatchResult(
    DeleteBatchGuestResponseModel model,
  ) {
    return DeleteBatchResult(
      deletedCount:
          AppSanitizer.cleanInteger(model.deletedCount) ?? model.deletedCount,
    );
  }
}
