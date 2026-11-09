import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_guest/delete_guest_params.dart';

/// Use case untuk menghapus data tamu dari repositori.
///
/// Mengimplementasikan GoF Command Pattern melalui abstraksi [UseCase],
/// memastikan pemisahan tanggung jawab bisnis dari lapisan presentasi
/// dan data.
class DeleteGuestUseCase implements UseCase<void, DeleteGuestParams> {
  /// Membuat instance [DeleteGuestUseCase].
  const DeleteGuestUseCase(this.repository);

  /// Kontrak repositori data tamu (Dependency Inversion / Strategy Pattern).
  final GuestRepository repository;

  @override
  Future<Either<Failure, void>> call(DeleteGuestParams params) async {
    // Validasi domain invariant: ID wajib diisi dan berupa angka
    if (!params.isValidId) {
      return const Left(
        ValidationFailure('ID tamu wajib diisi dan harus berupa angka valid.'),
      );
    }

    // Otorisasi: hanya ADMIN atau pembuat (GUARD) yang boleh menghapus.
    if (!params.isAuthorized) {
      return const Left(
        ForbiddenFailure(
          'Anda tidak memiliki izin untuk menghapus data tamu ini.',
        ),
      );
    }

    return await repository.deleteGuest(
      id: params.id,
      cancelToken: params.cancelToken,
    );
  }
}
