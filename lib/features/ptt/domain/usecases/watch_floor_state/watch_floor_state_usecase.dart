import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_floor_state_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_repository.dart';

/// UseCase untuk memantau aliran perubahan status pendudukan saluran PTT
/// secara real-time.
class WatchFloorStateUseCase {
  const WatchFloorStateUseCase(this.repository);

  final PttRepository repository;

  Stream<PttFloorStateEntity> call() {
    return repository.watchFloorState();
  }
}
