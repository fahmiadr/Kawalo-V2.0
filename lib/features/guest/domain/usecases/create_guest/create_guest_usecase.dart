import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/create_guest/create_guest_params.dart';

/// Use case untuk mendaftarkan data tamu baru ke sistem backend.
///
/// Bertindak sebagai Single Source of Truth bagi aturan validasi bisnis domain
/// sebelum delegasi request ke repositori.
class CreateGuestUseCase
    implements UseCase<GuestItemEntity, CreateGuestParams> {
  /// Membuat instance [CreateGuestUseCase].
  const CreateGuestUseCase(this.repository);

  /// Repositori data tamu.
  final GuestRepository repository;

  @override
  Future<Either<Failure, GuestItemEntity>> call(CreateGuestParams params) {
    if (params.session != null && !params.isAuthorized) {
      return Future.value(
        const Left(
          ForbiddenFailure(
            'Anda tidak memiliki izin untuk mendaftarkan data tamu.',
          ),
        ),
      );
    }
    return repository.createGuest(params.toRepositoryData());
  }
}
