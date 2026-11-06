import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/features/ptt/data/datasources/ptt_native_platform_data_source.dart';
import 'package:kawalo_mobile/features/ptt/data/repositories/ptt_repository_impl.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_repository.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/join_channel/join_channel_usecase.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/start_transmission/start_transmission_usecase.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/stop_transmission/stop_transmission_usecase.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/watch_floor_state/watch_floor_state_usecase.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';

/// Feature Composition Root untuk modul Push-to-Talk (PTT).
///
/// Merangkai DataSources, Repositories, dan UseCases menjadi BLoC/Cubit
/// siap pakai tanpa mengekspos detail teknis ke `main.dart` atau Router.
///
/// Menghubungkan rotasi token `ApiClient.onTokenRefreshed` ke repositori
/// PTT secara terpisah tanpa melanggar prinsip Clean Architecture.
class PttModule {
  const PttModule._();

  static PttRepository createRepository({
    PttNativePlatformDataSource? dataSource,
  }) {
    return PttRepositoryImpl(
      dataSource: dataSource ?? PttNativePlatformDataSourceImpl(),
    );
  }

  static PttCubit createCubit({
    ApiClient? apiClient,
    PttRepository? repository,
  }) {
    final repo = repository ?? createRepository();

    // Hubungkan hook rotasi token access token ke background service
    if (apiClient != null) {
      apiClient.onTokenRefreshed = repo.updateAuthToken;
    }

    return PttCubit(
      joinChannelUseCase: JoinChannelUseCase(repo),
      startTransmissionUseCase: StartTransmissionUseCase(repo),
      stopTransmissionUseCase: StopTransmissionUseCase(repo),
      repository: repo,
    );
  }

  static WatchFloorStateUseCase createWatchFloorStateUseCase({
    PttRepository? repository,
  }) {
    return WatchFloorStateUseCase(repository ?? createRepository());
  }
}
