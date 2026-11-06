import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/domain/repositories/auth_repository.dart';

class LoginParams extends Equatable {
  const LoginParams({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  LoginUseCase(this.repository, {this.cacheWiper});
  final AuthRepository repository;
  final CacheWiper? cacheWiper;

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    final result = await repository.login(
      email: params.email,
      password: params.password,
    );

    return await result.fold(
      (failure) async => Left(failure),
      (user) async {
        await cacheWiper?.wipeAll();
        return Right(user);
      },
    );
  }
}
