import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/get_guests_params.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/guest_result.dart';

/// Use case untuk mengambil daftar tamu dari repository.
class GetGuestsUseCase implements UseCase<GuestResult, GetGuestsParams> {
  /// Membuat instance [GetGuestsUseCase].
  const GetGuestsUseCase(this.repository);

  /// Repositori data tamu.
  final GuestRepository repository;

  @override
  Future<Either<Failure, GuestResult>> call(GetGuestsParams params) {
    return repository.getGuests(params);
  }
}
