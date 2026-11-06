import 'package:kawalo_mobile/core/utils/app_sanitizer.dart';
import 'package:kawalo_mobile/features/group/data/models/group_member_model.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';

/// Mapper statis untuk konversi [GroupMemberModel] ke [GroupMemberEntity]
/// dengan Anti-Corruption Layer (ACL) sanitasi.
abstract final class GroupMemberMapper {
  /// Mengonversi DTO [GroupMemberModel] ke Domain Entity [GroupMemberEntity]
  /// dengan sanitasi string dan email.
  static GroupMemberEntity toEntity(GroupMemberModel model) {
    return GroupMemberEntity(
      email: AppSanitizer.cleanEmail(model.email) ??
          model.email.trim().toLowerCase(),
      name: AppSanitizer.cleanString(model.name),
      profilePic: AppSanitizer.cleanString(model.profilePic),
    );
  }

  /// Mengonversi list DTO ke list Domain Entity sebagai fixed-length list.
  static List<GroupMemberEntity> toEntityList(List<GroupMemberModel> models) {
    return models.map(toEntity).toList(growable: false);
  }
}
