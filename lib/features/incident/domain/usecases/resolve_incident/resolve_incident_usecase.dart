import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/repositories/incident_repository.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/resolve_incident/resolve_incident_params.dart';

/// Use case untuk menyelesaikan insiden dan mengunci thread diskusi ke mode
/// read-only.
class ResolveIncidentUseCase
    implements UseCase<IncidentEntity, ResolveIncidentParams> {
  /// Membuat instance [ResolveIncidentUseCase].
  const ResolveIncidentUseCase(this.repository);

  /// Repositori insiden.
  final IncidentRepository repository;

  @override
  Future<Either<Failure, IncidentEntity>> call(
    ResolveIncidentParams params,
  ) async {
    if (!params.isAuthorized) {
      return const Left(
        ForbiddenFailure(
          'Anda tidak memiliki izin atau insiden telah diselesaikan '
              'sebelumnya.',
        ),
      );
    }

    return await repository.resolveIncident(
      incidentId: params.incident.id,
      cancelToken: params.cancelToken,
    );
  }
}
