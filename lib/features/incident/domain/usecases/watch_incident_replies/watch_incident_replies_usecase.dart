import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_stream_event.dart';
import 'package:kawalo_mobile/features/incident/domain/repositories/incident_repository.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/watch_incident_replies/watch_incident_replies_params.dart';

/// Use case untuk berlangganan pesan balasan dan event realtime thread
/// insiden via SSE.
class WatchIncidentRepliesUseCase {
  /// Membuat instance [WatchIncidentRepliesUseCase].
  const WatchIncidentRepliesUseCase(this.repository);

  /// Repositori insiden.
  final IncidentRepository repository;

  /// Membuka stream event realtime insiden.
  Stream<Either<Failure, IncidentStreamEvent>> call(
    WatchIncidentRepliesParams params,
  ) async* {
    if (!params.isAuthorized) {
      yield const Left(
        ForbiddenFailure(
          'Sesi tidak valid untuk memantau stream insiden.',
        ),
      );
      return;
    }

    yield* repository.watchIncidentReplies(
      incidentId: params.incidentId,
      lastEventId: params.lastEventId,
      cancelToken: params.cancelToken,
    );
  }
}
