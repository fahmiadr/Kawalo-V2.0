import 'package:kawalo_mobile/core/utils/app_sanitizer.dart';
import 'package:kawalo_mobile/features/guest/data/models/master_guest_type_model.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/master_guest_type_entity.dart';

/// Mapper untuk konversi antara [MasterGuestTypeModel] (DTO) dan
/// [MasterGuestTypeEntity] (Domain Entity).
abstract final class MasterGuestTypeMapper {
  /// Mengonversi satu instance [MasterGuestTypeModel] menjadi
  /// [MasterGuestTypeEntity].
  static MasterGuestTypeEntity toEntity(MasterGuestTypeModel model) {
    return MasterGuestTypeEntity(
      id: AppSanitizer.cleanString(model.id) ?? model.id.trim(),
      uid: AppSanitizer.cleanString(model.uid) ?? model.uid.trim(),
      name: AppSanitizer.cleanString(model.name) ?? model.name.trim(),
    );
  }

  /// Mengonversi daftar [MasterGuestTypeModel] menjadi daftar
  /// [MasterGuestTypeEntity].
  static List<MasterGuestTypeEntity> toEntityList(
    List<MasterGuestTypeModel> models,
  ) {
    return models.map(toEntity).toList(growable: false);
  }
}
