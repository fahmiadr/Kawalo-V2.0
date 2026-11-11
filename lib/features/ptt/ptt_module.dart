import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/core/config/env_config.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/features/ptt/data/datasources/ptt_member_remote_data_source.dart';
import 'package:kawalo_mobile/features/ptt/data/datasources/ptt_native_platform_data_source.dart';
import 'package:kawalo_mobile/features/ptt/data/datasources/ptt_recording_remote_data_source.dart';
import 'package:kawalo_mobile/features/ptt/data/datasources/ptt_transcript_local_data_source.dart';
import 'package:kawalo_mobile/features/ptt/data/datasources/ptt_transcript_remote_data_source.dart';
import 'package:kawalo_mobile/features/ptt/data/repositories/ptt_member_repository_impl.dart';
import 'package:kawalo_mobile/features/ptt/data/repositories/ptt_recording_repository_impl.dart';
import 'package:kawalo_mobile/features/ptt/data/repositories/ptt_repository_impl.dart';
import 'package:kawalo_mobile/features/ptt/data/repositories/ptt_transcript_repository_impl.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_member_repository.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_recording_repository.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_repository.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_transcript_repository.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/join_channel/join_channel_usecase.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/start_transmission/start_transmission_usecase.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/services/ptt_transcript_uploader.dart';

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

  static PttRecordingRepository createRecordingRepository({
    required ApiClient apiClient,
  }) {
    return PttRecordingRepositoryImpl(
      remoteDataSource: PttRecordingRemoteDataSourceImpl(apiClient: apiClient),
    );
  }

  static PttMemberRepository createMemberRepository({
    required ApiClient apiClient,
  }) {
    return PttMemberRepositoryImpl(
      remoteDataSource: PttMemberRemoteDataSourceImpl(apiClient: apiClient),
    );
  }

  static PttCubit createCubit({
    ApiClient? apiClient,
    PttRepository? repository,
    SecureStorageService? storageService,
  }) {
    final repo = repository ?? createRepository();

    // Hubungkan hook rotasi token access token ke background service
    if (apiClient != null) {
      apiClient.onTokenRefreshed = repo.updateAuthToken;
    }

    return PttCubit(
      joinChannelUseCase: JoinChannelUseCase(repo),
      startTransmissionUseCase: StartTransmissionUseCase(repo),
      repository: repo,
      storageService: storageService,
      apiBaseUrl: () => EnvConfig.apiBaseUrl,
      refreshAccessToken: apiClient == null
          ? null
          : () async {
              await apiClient.refreshAccessToken();
            },
    );
  }
}

/// Owns the Isar outbox of transcript reports, so it is wiped on logout like
/// the feature caches.
final class PttTranscriptModule implements CacheWipeableModule {
  PttTranscriptModule({required ApiClient apiClient, required Isar isar}) {
    final localDataSource = PttTranscriptLocalDataSourceImpl(isar: isar);
    cacheWipeable = localDataSource;
    repository = PttTranscriptRepositoryImpl(
      remoteDataSource: PttTranscriptRemoteDataSourceImpl(apiClient: apiClient),
      localDataSource: localDataSource,
    );
  }

  late final PttTranscriptRepository repository;

  @override
  late final CacheWipeable cacheWipeable;

  /// [pttRepository] must be the instance the `PttCubit` uses: the native
  /// event channel supports a single Dart listener.
  PttTranscriptUploader createUploader({
    required PttRepository pttRepository,
    required Stream<bool> connectivity,
    required UserSessionCubit session,
  }) {
    return PttTranscriptUploader(
      repository: repository,
      transcripts: pttRepository.watchTranscripts(),
      connectivity: connectivity,
      session: session,
    );
  }
}
