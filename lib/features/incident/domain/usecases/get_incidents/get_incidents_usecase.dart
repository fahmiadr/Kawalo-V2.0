import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/repositories/incident_repository.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/get_incidents/get_incidents_params.dart';

/// Use case untuk mengambil daftar laporan insiden aktif/selesai dalam grup pengguna.
class GetIncidentsUseCase
    implements UseCase<List<IncidentEntity>, GetIncidentsParams> {
  /// Membuat instance [GetIncidentsUseCase].
  const GetIncidentsUseCase(this.repository);

  /// Repositori insiden.
  final IncidentRepository repository;

  @override
  Future<Either<Failure, List<IncidentEntity>>> call(
    GetIncidentsParams params,
  ) async {
    if (!params.isAuthorized) {
      return const Left(
        ForbiddenFailure(
          'Anda tidak memiliki izin untuk melihat daftar insiden grup ini.',
        ),
      );
    }

    return await repository.getIncidents(params.toQueryParams());
  }
}
