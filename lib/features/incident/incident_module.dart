import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
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
final class IncidentModule {
  IncidentModule({
    required ApiClient apiClient,
    required NetworkInfo networkInfo,
  }) : repository = IncidentRepositoryImpl(
         remoteDataSource: IncidentRemoteDataSourceImpl(apiClient: apiClient),
         networkInfo: networkInfo,
       );
  final IncidentRepository repository;

  /// Merakit dan mengembalikan instance [IncidentListCubit] yang siap pakai.
  IncidentListCubit createIncidentListCubit() {
    return IncidentListCubit(
      getIncidentsUseCase: GetIncidentsUseCase(repository),
    );
  }

  /// Merakit dan mengembalikan instance [IncidentDetailCubit] untuk layar
  /// detail insiden.
  IncidentDetailCubit createIncidentDetailCubit({required String incidentId}) {
    return IncidentDetailCubit(
      incidentId: incidentId,
      getIncidentDetailUseCase: GetIncidentDetailUseCase(repository),
      watchIncidentRepliesUseCase: WatchIncidentRepliesUseCase(repository),
      postIncidentReplyUseCase: PostIncidentReplyUseCase(repository),
      resolveIncidentUseCase: ResolveIncidentUseCase(repository),
      deleteIncidentUseCase: DeleteIncidentUseCase(repository),
    );
  }

  /// Merakit dan mengembalikan instance [IncidentFormCubit] untuk pelaporan
  /// insiden baru.
  IncidentFormCubit createIncidentFormCubit() {
    return IncidentFormCubit(
      createIncidentUseCase: CreateIncidentUseCase(repository),
    );
  }
}
