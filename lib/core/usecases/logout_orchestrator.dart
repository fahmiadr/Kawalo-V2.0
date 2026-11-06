import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';

/// Orchestrator untuk mengoordinasikan pembersihan sesi dan seluruh cache
/// saat pengguna logout.
///
/// Mengimplementasikan prinsip Single Responsibility & Dependency Rule:
/// 1. Mendelegasikan pencabutan token dan pembersihan sesi ke
///    [authLogoutUseCase].
/// 2. Mengosongkan seluruh feature-level local cache (Isar) dan timestamp
///    sinkronisasi via [cacheWiper].
///
/// Menjamin pembersihan cache selalu dijalankan (best-effort) sekalipun
/// proses logout autentikasi mengalami kendala jaringan atau kegagalan teknis.
class LogoutOrchestrator implements UseCase<void, NoParams> {
  /// Membuat instance [LogoutOrchestrator].
  LogoutOrchestrator({
    required this.authLogoutUseCase,
    required this.cacheWiper,
  });

  /// UseCase logout autentikasi murni (mencabut token dan membersihkan sesi).
  final UseCase<void, NoParams> authLogoutUseCase;

  /// Koordinator pembersihan cache fitur lokal.
  final CacheWiper cacheWiper;

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      return await authLogoutUseCase(params);
    } on Object catch (e) {
      return Left(
        e is Failure ? e : ServerFailure(e.toString()),
      );
    } finally {
      // Menjamin pembersihan seluruh cache fitur lokal selalu dieksekusi
      // baik proses logout berhasil, gagal, maupun melempar exception.
      await cacheWiper.wipeAll();
    }
  }
}
