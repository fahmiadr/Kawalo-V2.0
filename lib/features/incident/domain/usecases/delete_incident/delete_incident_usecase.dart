import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/repositories/incident_repository.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/delete_incident/delete_incident_params.dart';

/// Use case untuk menghapus laporan insiden secara administratif (soft-delete).
class DeleteIncidentUseCase implements UseCase<void, DeleteIncidentParams> {
  /// Membuat instance [DeleteIncidentUseCase].
  const DeleteIncidentUseCase(this.repository);

  /// Repositori insiden.
  final IncidentRepository repository;

  @override
  Future<Either<Failure, void>> call(
    DeleteIncidentParams params,
  ) async {
    if (!params.isAuthorized) {
      return const Left(
        ForbiddenFailure(
          'Hanya administrator yang berhak menghapus laporan insiden.',
        ),
      );
    }

    return await repository.deleteIncident(
      incidentId: params.incident.id,
      cancelToken: params.cancelToken,
    );
  }
}
