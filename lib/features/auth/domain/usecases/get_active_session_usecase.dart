import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/repositories/auth_repository.dart';

/// Use case untuk mengambil data sesi autentikasi aktif pengguna.
class GetActiveSessionUseCase implements UseCase<AuthSessionEntity?, NoParams> {
  /// Membuat instance [GetActiveSessionUseCase].
  const GetActiveSessionUseCase(this.repository);

  /// Kontrak repositori autentikasi.
  final AuthRepository repository;

  @override
  Future<Either<Failure, AuthSessionEntity?>> call(NoParams params) =>
      repository.getActiveSession();
}
