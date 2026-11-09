import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/update_guest/update_guest_params.dart';

/// Use case untuk memperbarui data tamu yang sudah terdaftar.
///
/// Bertindak sebagai Single Source of Truth bagi aturan validasi bisnis domain
/// dan otorisasi sebelum mendelegasikan payload pembaruan ke repositori.
class UpdateGuestUseCase
    implements UseCase<GuestItemEntity, UpdateGuestParams> {
  /// Membuat instance [UpdateGuestUseCase].
  const UpdateGuestUseCase(this.repository);

  /// Repositori data tamu.
  final GuestRepository repository;

  @override
  Future<Either<Failure, GuestItemEntity>> call(
    UpdateGuestParams params,
  ) async {
    // 1. Validasi domain invariant: ID wajib diisi dan berupa angka
    if (!params.isValidId) {
      return const Left(
        ValidationFailure('ID tamu wajib diisi dan harus berupa angka valid.'),
      );
    }

    // 2. Otorisasi domain: hanya ADMIN atau pembuat tamu (GUARD) yang boleh
    // mengubah.
    if (!params.isAuthorized) {
      return const Left(
        ForbiddenFailure(
          'Anda tidak memiliki izin untuk mengubah data tamu ini.',
        ),
      );
    }

    return await repository.updateGuest(params.toRepositoryData());
  }
}
