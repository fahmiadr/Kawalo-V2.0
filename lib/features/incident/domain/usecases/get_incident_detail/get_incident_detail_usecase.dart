import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/repositories/incident_repository.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/get_incident_detail/get_incident_detail_params.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_detail_result.dart';

/// Use case untuk mengambil detail insiden dan riwayat balasan awal.
class GetIncidentDetailUseCase
    implements UseCase<IncidentDetailResult, GetIncidentDetailParams> {
  /// Membuat instance [GetIncidentDetailUseCase].
  const GetIncidentDetailUseCase(this.repository);

  /// Repositori insiden.
  final IncidentRepository repository;

  @override
  Future<Either<Failure, IncidentDetailResult>> call(
    GetIncidentDetailParams params,
  ) async {
    if (!params.isAuthorized) {
      return const Left(
        ForbiddenFailure(
          'Sesi tidak valid untuk melihat detail insiden.',
        ),
      );
    }

    final result = await repository.getIncidentDetail(
      incidentId: params.incidentId,
      cancelToken: params.cancelToken,
    );

    return result.flatMap((detail) {
      if (!detail.incident.canBeViewedBySession(params.session)) {
        return const Left(
          ForbiddenFailure(
            'Anda tidak memiliki akses untuk melihat insiden dari grup lain.',
          ),
        );
      }
      return Right(detail);
    });
  }
}
