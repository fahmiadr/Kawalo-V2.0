import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_batch_guest/delete_batch_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/delete_batch_result.dart';

/// Use case untuk menghapus sekumpulan data tamu dari repositori.
///
/// Mengimplementasikan GoF Command Pattern melalui abstraksi [UseCase],
/// memastikan pemisahan tanggung jawab bisnis dari lapisan presentasi
/// dan data.
class DeleteBatchGuestUseCase
    implements UseCase<DeleteBatchResult, DeleteBatchGuestParams> {
  /// Membuat instance [DeleteBatchGuestUseCase].
  const DeleteBatchGuestUseCase(this.repository);

  /// Kontrak repositori data tamu (Dependency Inversion / Strategy Pattern).
  final GuestRepository repository;

  @override
  Future<Either<Failure, DeleteBatchResult>> call(
    DeleteBatchGuestParams params,
  ) async {
    // Validasi domain invariant: daftar ID tidak boleh kosong dan seluruh item
    // harus numerik valid.
    if (!params.isValid) {
      return const Left(
        ValidationFailure(
          'Daftar ID tamu tidak boleh kosong dan seluruh ID harus berupa '
          'angka valid.',
        ),
      );
    }

    // Otorisasi: seluruh item harus boleh dihapus oleh sesi aktif.
    if (!params.isAuthorized) {
      return const Left(
        ForbiddenFailure(
          'Anda tidak memiliki izin untuk menghapus salah satu data tamu '
          'yang dipilih.',
        ),
      );
    }

    return await repository.deleteBatchGuests(
      ids: params.ids,
      cancelToken: params.cancelToken,
    );
  }
}
