import 'package:kawalo_mobile/core/utils/app_sanitizer.dart';
import 'package:kawalo_mobile/features/information/data/models/delete_batch_information_response_model.dart';
import 'package:kawalo_mobile/features/information/data/models/information_model.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/delete_batch_result.dart';

/// Mapper yang bertanggung jawab atas translasi data antara
/// [InformationModel] (Data Layer DTO) dan [InformationItemEntity]
/// (Domain Layer Entity).
///
/// Mengikuti pola Dedicated Mapper yang selaras dengan backend API
/// (`InformationResponseMapper`) dengan Anti-Corruption Layer (ACL) sanitasi.
abstract final class InformationMapper {
  /// Mengonversi satu instance [InformationModel] menjadi
  /// [InformationItemEntity] dengan sanitasi data tanpa fallback.
  static InformationItemEntity toEntity(InformationModel model) {
    return InformationItemEntity(
      id: AppSanitizer.cleanString(model.id) ?? model.id.trim(),
      photos: AppSanitizer.cleanStringList(model.photos),
      title: AppSanitizer.cleanString(model.title),
      text: AppSanitizer.cleanString(model.text),
      userEmail: AppSanitizer.cleanEmail(model.userEmail),
      userName: AppSanitizer.cleanString(model.userName),
      userProfilePic: AppSanitizer.cleanString(model.userProfilePic),
      feedDt: AppSanitizer.cleanDate(model.feedDt),
      feedFile: AppSanitizer.cleanString(model.feedFile),
      feedType: AppSanitizer.cleanString(model.feedType),
      groupName: AppSanitizer.cleanString(model.groupName),
      eventLocation: AppSanitizer.cleanString(model.eventLocation),
      eventStartDt: AppSanitizer.cleanDate(model.eventStartDt),
      eventEndDt: AppSanitizer.cleanDate(model.eventEndDt),
      eventDuration: AppSanitizer.cleanInteger(model.eventDuration),
      glat: AppSanitizer.cleanLatitudeDouble(model.glat),
      glong: AppSanitizer.cleanLongitudeDouble(model.glong),
    );
  }

  /// Mengonversi daftar [InformationModel] menjadi daftar
  /// [InformationItemEntity].
  static List<InformationItemEntity> toEntityList(
    List<InformationModel> models,
  ) {
    return models.map(toEntity).toList(growable: false);
  }

  /// Mengonversi [DeleteBatchInformationResponseModel] (DTO) menjadi
  /// [DeleteBatchResult] (Domain Response Model).
  static DeleteBatchResult toDeleteBatchResult(
    DeleteBatchInformationResponseModel model,
  ) {
    return DeleteBatchResult(
      deletedCount:
          AppSanitizer.cleanInteger(model.deletedCount) ?? model.deletedCount,
    );
  }
}
