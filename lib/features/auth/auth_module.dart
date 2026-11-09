import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/security/jwks_service.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/core/usecases/logout_orchestrator.dart';
import 'package:kawalo_mobile/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:kawalo_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:kawalo_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kawalo_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/get_active_session_usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:kawalo_mobile/features/auth/domain/usecases/switch_group_usecase.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';

/// Feature Composition Root untuk modul Autentikasi pada Frontend.
///
/// Bertanggung jawab atas inisialisasi dan perakitan Dependency Injection
/// (DataSources -> Repository -> UseCases -> Bloc) di tingkat fitur,
/// selaras dengan pola modular Clean Architecture.
abstract final class AuthModule {
  /// Merakit dan mengembalikan instance [AuthRepository] yang siap pakai.
  static AuthRepository createRepository({
    required ApiClient apiClient,
    required SecureStorageService storageService,
    required JwksService jwksService,
  }) {
    final remoteDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);

    final localDataSource = AuthLocalDataSourceImpl(
      storageService: storageService,
    );

    return AuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      apiClient: apiClient,
      jwksService: jwksService,
    );
  }

  /// Merakit dan mengembalikan instance [AuthBloc] yang siap pakai.
  ///
  /// Bila [cacheWiper] disertakan, [LogoutOrchestrator] akan digunakan untuk
  /// mengoordinasikan pembersihan sesi dan cache Isar, serta [cacheWiper]
  /// dipasang ke [LoginUseCase] dan [SwitchGroupUseCase] sebagai safety-net.
  static AuthBloc createBloc({
    required AuthRepository repository,
    CacheWiper? cacheWiper,
  }) {
    final loginUseCase = LoginUseCase(repository, cacheWiper: cacheWiper);
    final switchGroupUseCase = SwitchGroupUseCase(
      repository,
      cacheWiper: cacheWiper,
    );
    final getCurrentUserUseCase = GetCurrentUserUseCase(repository);
    final rawLogoutUseCase = LogoutUseCase(repository);
    final logoutUseCase = cacheWiper != null
        ? LogoutOrchestrator(
            authLogoutUseCase: rawLogoutUseCase,
            cacheWiper: cacheWiper,
          )
        : rawLogoutUseCase;
    final getActiveSessionUseCase = GetActiveSessionUseCase(repository);

    return AuthBloc(
      loginUseCase: loginUseCase,
      switchGroupUseCase: switchGroupUseCase,
      getCurrentUserUseCase: getCurrentUserUseCase,
      logoutUseCase: logoutUseCase,
      getActiveSessionUseCase: getActiveSessionUseCase,
    );
  }
}
