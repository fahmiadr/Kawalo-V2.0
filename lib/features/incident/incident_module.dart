import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';
import 'package:kawalo_mobile/features/incident/data/datasources/incident_local_data_source.dart';
import 'package:kawalo_mobile/features/incident/data/datasources/incident_remote_data_source.dart';
import 'package:kawalo_mobile/features/incident/data/repositories/incident_repository_impl.dart';
import 'package:kawalo_mobile/features/incident/domain/repositories/incident_repository.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/create_incident/create_incident_usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/delete_incident/delete_incident_usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/get_incident_detail/get_incident_detail_usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/get_incidents/get_incidents_usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/post_incident_reply/post_incident_reply_usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/resolve_incident/resolve_incident_usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/watch_incident_replies/watch_incident_replies_usecase.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_detail_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_form_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_cubit.dart';

/// Feature Composition Root untuk fitur Insiden.
///
/// Receives the shared dependencies once and builds a single
/// [IncidentRepository] that every cubit factory reuses. Registered through
/// `RepositoryProvider` so the presentation layer never assembles dependencies
/// itself.
final class IncidentModule implements CacheWipeableModule {
  IncidentModule({
    required ApiClient apiClient,
    required Isar isar,
    required NetworkInfo networkInfo,
    required SyncStorageService syncStorageService,
  }) : _syncStorage = syncStorageService {
    final localDataSource = IncidentLocalDataSourceImpl(isar: isar);
    cacheWipeable = localDataSource;
    repository = IncidentRepositoryImpl(
      remoteDataSource: IncidentRemoteDataSourceImpl(apiClient: apiClient),
      localDataSource: localDataSource,
      syncStorageService: syncStorageService,
      networkInfo: networkInfo,
    );
  }

  final SyncStorageService _syncStorage;
  late final IncidentRepository repository;

  @override
  late final CacheWipeable cacheWipeable;

  /// Merakit dan mengembalikan instance [IncidentListCubit] yang siap pakai.
  IncidentListCubit createIncidentListCubit() {
    return IncidentListCubit(
      getIncidentsUseCase: GetIncidentsUseCase(repository),
      syncStorageService: _syncStorage,
    );
  }

  /// Merakit dan mengembalikan instance [IncidentDetailCubit] untuk layar
  /// detail insiden.
  IncidentDetailCubit createIncidentDetailCubit({
    required String incidentId,
    required UploadRepository uploadRepository,
  }) {
    return IncidentDetailCubit(
      incidentId: incidentId,
      getIncidentDetailUseCase: GetIncidentDetailUseCase(repository),
      watchIncidentRepliesUseCase: WatchIncidentRepliesUseCase(repository),
      postIncidentReplyUseCase: PostIncidentReplyUseCase(repository),
      resolveIncidentUseCase: ResolveIncidentUseCase(repository),
      deleteIncidentUseCase: DeleteIncidentUseCase(repository),
      uploadRepository: uploadRepository,
    );
  }

  /// Merakit dan mengembalikan instance [IncidentFormCubit] untuk pelaporan
  /// insiden baru.
  IncidentFormCubit createIncidentFormCubit({
    required UploadRepository uploadRepository,
  }) {
    return IncidentFormCubit(
      createIncidentUseCase: CreateIncidentUseCase(repository),
      uploadRepository: uploadRepository,
    );
  }
}
