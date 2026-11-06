import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/master_guest_type_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/get_master_guest_types/get_master_guest_types_params.dart';

/// Use case untuk mengambil daftar master tipe tamu dari grup aktif.
class GetMasterGuestTypesUseCase
    implements UseCase<List<MasterGuestTypeEntity>, GetMasterGuestTypesParams> {
  /// Membuat instance [GetMasterGuestTypesUseCase].
  const GetMasterGuestTypesUseCase(this.repository);

  /// Repositori data tamu.
  final GuestRepository repository;

  @override
  Future<Either<Failure, List<MasterGuestTypeEntity>>> call(
    GetMasterGuestTypesParams params,
  ) {
    return repository.getMasterGuestTypes(cancelToken: params.cancelToken);
  }
}
