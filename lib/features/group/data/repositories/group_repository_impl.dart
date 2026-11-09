import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/group/data/datasources/group_remote_data_source.dart';
import 'package:kawalo_mobile/features/group/data/mappers/group_member_mapper.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';
import 'package:kawalo_mobile/features/group/domain/repositories/group_repository.dart';

/// Implementasi konkret dari [GroupRepository] yang berkomunikasi
/// dengan [GroupRemoteDataSource].
class GroupRepositoryImpl implements GroupRepository {
  /// Membuat instance [GroupRepositoryImpl].
  const GroupRepositoryImpl({required this.remoteDataSource, this.networkInfo});

  /// Sumber data jarak jauh anggota grup.
  final GroupRemoteDataSource remoteDataSource;

  /// Utilitas pengecekan konektivitas jaringan perangkat.
  final NetworkInfo? networkInfo;

  @override
  Future<Either<Failure, List<GroupMemberEntity>>> getMembers({
    AppCancellationToken? cancelToken,
  }) async {
    // 1. Guard Jaringan: Operasi pengambilan data membutuhkan koneksi aktif
    final isConnected = await (networkInfo?.isConnected ?? Future.value(true));
    if (!isConnected) {
      return const Left(NoInternetFailure());
    }

    try {
      final models = await remoteDataSource.getMembers(
        cancelToken: cancelToken,
      );
      final entities = GroupMemberMapper.toEntityList(models);
      return Right(entities);
    } on AppException catch (e) {
      if (e is RequestCancelledException) {
        return const Left(RequestCancelledFailure());
      }
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }
}
