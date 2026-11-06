import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/information/domain/repositories/information_repository.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/get_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/information_result.dart';

/// Use case untuk mengambil daftar informasi / feed dari repositori.
class GetInformationUseCase
    implements UseCase<InformationResult, GetInformationParams> {
  /// Membuat instance [GetInformationUseCase].
  const GetInformationUseCase(this.repository);

  /// Repositori data informasi.
  final InformationRepository repository;

  @override
  Future<Either<Failure, InformationResult>> call(
    GetInformationParams params,
  ) {
    return repository.getInformation(params);
  }
}
