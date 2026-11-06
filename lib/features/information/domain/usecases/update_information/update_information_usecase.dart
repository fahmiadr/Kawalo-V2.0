import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/repositories/information_repository.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/update_information/update_information_params.dart';

/// Use case untuk memperbarui data informasi / feed yang sudah ada.
///
/// Bertindak sebagai Single Source of Truth bagi aturan validasi bisnis domain
/// dan otorisasi sebelum mendelegasikan payload pembaruan ke repositori.
class UpdateInformationUseCase
    implements UseCase<InformationItemEntity, UpdateInformationParams> {
  /// Membuat instance [UpdateInformationUseCase].
  const UpdateInformationUseCase(this.repository);

  /// Repositori data informasi.
  final InformationRepository repository;

  @override
  Future<Either<Failure, InformationItemEntity>> call(
    UpdateInformationParams params,
  ) async {
    // Validasi domain invariant: ID wajib diisi dan berupa angka
    if (!params.isValidId) {
      return const Left(
        ValidationFailure(
          'ID informasi wajib diisi dan harus berupa angka valid.',
        ),
      );
    }

    // Otorisasi: hanya ADMIN atau pembuat (GUARD) yang boleh mengubah.
    if (!params.isAuthorized) {
      return const Left(
        ForbiddenFailure(
          'Anda tidak memiliki izin untuk mengubah informasi ini.',
        ),
      );
    }

    return await repository.updateInformation(params.toRepositoryData());
  }
}
