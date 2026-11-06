import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/repositories/information_repository.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/create_information/create_information_params.dart';

/// Use case untuk mempublikasikan data informasi / feed baru ke sistem backend.
///
/// Bertindak sebagai Single Source of Truth bagi aturan validasi bisnis domain
/// dan otorisasi sebelum mendelegasikan payload ke repositori.
class CreateInformationUseCase
    implements UseCase<InformationItemEntity, CreateInformationParams> {
  /// Membuat instance [CreateInformationUseCase].
  const CreateInformationUseCase(this.repository);

  /// Repositori data informasi.
  final InformationRepository repository;

  @override
  Future<Either<Failure, InformationItemEntity>> call(
    CreateInformationParams params,
  ) async {
    // Otorisasi: hanya pengguna dengan role ADMIN atau GUARD yang dapat
    // membuat informasi.
    if (!params.isAuthorized) {
      return const Left(
        ForbiddenFailure(
          'Anda tidak memiliki izin untuk membuat informasi.',
        ),
      );
    }

    return await repository.createInformation(params.toRepositoryData());
  }
}
