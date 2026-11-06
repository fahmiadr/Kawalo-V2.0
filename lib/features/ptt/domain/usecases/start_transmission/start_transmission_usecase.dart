import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_repository.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/start_transmission/start_transmission_params.dart';

/// UseCase untuk mengirim permintaan hak bicara (Floor Request).
class StartTransmissionUseCase
    implements UseCase<void, StartTransmissionParams> {
  const StartTransmissionUseCase(this.repository);

  final PttRepository repository;

  @override
  Future<Either<Failure, void>> call(StartTransmissionParams params) {
    if (params.requestId.trim().isEmpty) {
      return Future.value(
        const Left(
          ServerFailure('Request ID transmisi PTT tidak boleh kosong.'),
        ),
      );
    }

    return repository.startTransmission(requestId: params.requestId);
  }
}
