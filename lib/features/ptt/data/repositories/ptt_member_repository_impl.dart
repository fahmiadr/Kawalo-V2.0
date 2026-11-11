import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/features/ptt/data/datasources/ptt_member_remote_data_source.dart';
import 'package:kawalo_mobile/features/ptt/data/mappers/ptt_member_mapper.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_member_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_member_repository.dart';

class PttMemberRepositoryImpl implements PttMemberRepository {
  const PttMemberRepositoryImpl({required this.remoteDataSource});

  final PttMemberRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, List<PttMemberEntity>>> getMembers() async {
    try {
      final models = await remoteDataSource.getMembers();
      return Right(models.map(PttMemberMapper.toEntity).toList());
    } on Object catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }
}
