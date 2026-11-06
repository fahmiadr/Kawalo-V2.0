import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';

/// Kontrak abstrak repositori untuk manajemen data domain grup.
abstract class GroupRepository {
  /// Mengambil daftar seluruh anggota yang aktif tergabung dalam grup saat ini.
  Future<Either<Failure, List<GroupMemberEntity>>> getMembers({
    AppCancellationToken? cancelToken,
  });
}
