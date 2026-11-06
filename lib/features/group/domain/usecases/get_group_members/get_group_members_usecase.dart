import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';
import 'package:kawalo_mobile/features/group/domain/repositories/group_repository.dart';
import 'package:kawalo_mobile/features/group/domain/usecases/get_group_members/get_group_members_params.dart';

/// Use case untuk mengambil daftar seluruh anggota dalam grup aktif.
class GetGroupMembersUseCase
    implements UseCase<List<GroupMemberEntity>, GetGroupMembersParams> {
  /// Membuat instance [GetGroupMembersUseCase].
  const GetGroupMembersUseCase(this.repository);

  /// Repositori grup domain.
  final GroupRepository repository;

  @override
  Future<Either<Failure, List<GroupMemberEntity>>> call(
    GetGroupMembersParams params,
  ) {
    return repository.getMembers(cancelToken: params.cancelToken);
  }
}
