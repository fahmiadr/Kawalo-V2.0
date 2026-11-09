import 'package:fpdart/fpdart.dart' show Either;
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/widgets/app_user_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';

/// Pemetaan [GroupMemberEntity] ke [UserFilterOption] untuk
/// [AppUserFilterBottomSheet].
extension GroupMemberFilterOption on GroupMemberEntity {
  /// Opsi pemilih personil setara dengan anggota grup ini.
  UserFilterOption toFilterOption() => UserFilterOption(
        email: email,
        name: name,
        profilePic: profilePic,
      );
}

/// Membungkus pemuat anggota grup menjadi pemuat opsi untuk
/// [AppUserFilterBottomSheet.onLoadUsers].
Future<Either<Failure, List<UserFilterOption>>> loadGroupMemberFilterOptions(
  Future<Either<Failure, List<GroupMemberEntity>>> Function() load,
) async {
  final result = await load();
  return result.map(
    (members) => members.map((m) => m.toFilterOption()).toList(),
  );
}
