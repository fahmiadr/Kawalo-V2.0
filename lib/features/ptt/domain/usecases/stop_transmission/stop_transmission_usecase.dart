import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_repository.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/stop_transmission/stop_transmission_params.dart';

/// UseCase untuk melepaskan hak bicara (Floor Release).
class StopTransmissionUseCase implements UseCase<void, StopTransmissionParams> {
  const StopTransmissionUseCase(this.repository);

  final PttRepository repository;

  @override
  Future<Either<Failure, void>> call(StopTransmissionParams params) {
    return repository.stopTransmission();
  }
}
