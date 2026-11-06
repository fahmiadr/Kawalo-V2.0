import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/information/domain/repositories/information_repository.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/delete_batch_information/delete_batch_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/delete_batch_result.dart';

/// Use case untuk menghapus sekumpulan data informasi / feed dari repositori.
///
/// Mengimplementasikan GoF Command Pattern melalui abstraksi [UseCase],
/// memastikan pemisahan tanggung jawab bisnis dari lapisan presentasi
/// dan data.
class DeleteBatchInformationUseCase
    implements UseCase<DeleteBatchResult, DeleteBatchInformationParams> {
  /// Membuat instance [DeleteBatchInformationUseCase].
  const DeleteBatchInformationUseCase(this.repository);

  /// Kontrak repositori informasi (Dependency Inversion / Strategy Pattern).
  final InformationRepository repository;

  @override
  Future<Either<Failure, DeleteBatchResult>> call(
    DeleteBatchInformationParams params,
  ) async {
    // Validasi domain invariant: daftar ID tidak boleh kosong dan seluruh item
    // harus numerik valid.
    if (!params.isValid) {
      return const Left(
        ValidationFailure(
          'Daftar ID informasi tidak boleh kosong dan seluruh ID harus berupa '
          'angka valid.',
        ),
      );
    }

    // Otorisasi: seluruh item harus boleh dihapus oleh sesi aktif.
    if (!params.isAuthorized) {
      return const Left(
        ForbiddenFailure(
          'Anda tidak memiliki izin untuk menghapus salah satu informasi '
          'yang dipilih.',
        ),
      );
    }

    return await repository.deleteBatchInformation(
      ids: params.ids,
      cancelToken: params.cancelToken,
    );
  }
}
