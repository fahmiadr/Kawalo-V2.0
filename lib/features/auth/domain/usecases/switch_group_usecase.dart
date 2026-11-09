import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/domain/repositories/auth_repository.dart';

class SwitchGroupParams extends Equatable {
  const SwitchGroupParams({required this.groupUid});
  final String groupUid;

  @override
  List<Object?> get props => [groupUid];
}

class SwitchGroupUseCase implements UseCase<UserEntity, SwitchGroupParams> {
  SwitchGroupUseCase(this.repository, {this.cacheWiper});
  final AuthRepository repository;
  final CacheWiper? cacheWiper;

  @override
  Future<Either<Failure, UserEntity>> call(SwitchGroupParams params) async {
    final result = await repository.switchGroup(groupUid: params.groupUid);
    return await result.fold((failure) async => Left(failure), (user) async {
      await cacheWiper?.wipeAll();
      return Right(user);
    });
  }
}
