import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/repositories/incident_repository.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/create_incident/create_incident_params.dart';

/// Use case untuk membuat laporan insiden baru.
class CreateIncidentUseCase
    implements UseCase<IncidentEntity, CreateIncidentParams> {
  /// Membuat instance [CreateIncidentUseCase].
  const CreateIncidentUseCase(this.repository);

  /// Repositori insiden.
  final IncidentRepository repository;

  @override
  Future<Either<Failure, IncidentEntity>> call(
    CreateIncidentParams params,
  ) async {
    if (!params.isAuthorized) {
      return const Left(
        ForbiddenFailure(
          'Anda tidak memiliki izin untuk membuat laporan insiden.',
        ),
      );
    }

    if (params.title.trim().isEmpty) {
      return const Left(ValidationFailure('Judul insiden wajib diisi.'));
    }

    return await repository.createIncident(params.toRepositoryData());
  }
}
