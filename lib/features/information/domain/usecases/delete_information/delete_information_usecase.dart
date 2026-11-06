import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/information/domain/repositories/information_repository.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/delete_information/delete_information_params.dart';

/// Use case untuk menghapus data informasi / feed dari repositori.
///
/// Mengimplementasikan GoF Command Pattern melalui abstraksi [UseCase],
/// memastikan pemisahan tanggung jawab bisnis dari lapisan presentasi
/// dan data.
class DeleteInformationUseCase
    implements UseCase<void, DeleteInformationParams> {
  /// Membuat instance [DeleteInformationUseCase].
  const DeleteInformationUseCase(this.repository);

  /// Kontrak repositori informasi (Dependency Inversion / Strategy Pattern).
  final InformationRepository repository;

  @override
  Future<Either<Failure, void>> call(DeleteInformationParams params) async {
    // Validasi domain invariant: ID wajib diisi dan berupa angka
    if (!params.isValidId) {
      return const Left(
        ValidationFailure(
          'ID informasi wajib diisi dan harus berupa angka valid.',
        ),
      );
    }

    // Otorisasi: hanya ADMIN atau pembuat (GUARD) yang boleh menghapus.
    if (!params.isAuthorized) {
      return const Left(
        ForbiddenFailure(
          'Anda tidak memiliki izin untuk menghapus informasi ini.',
        ),
      );
    }

    return await repository.deleteInformation(
      id: params.id,
      cancelToken: params.cancelToken,
    );
  }
}
