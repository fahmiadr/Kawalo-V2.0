import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/operational/domain/repositories/operational_repository.dart';
import 'package:kawalo_mobile/features/operational/domain/value_objects/get_operationals_params.dart';
import 'package:kawalo_mobile/features/operational/domain/value_objects/operational_result.dart';

/// Use case untuk mengambil daftar personil tenaga kerja operasional dengan
/// transparansi sumber data (cache offline vs server remote).
class GetOperationalsUseCase
    implements UseCase<OperationalResult, GetOperationalsParams> {
  /// Membuat instance [GetOperationalsUseCase].
  const GetOperationalsUseCase(this.repository);

  /// Repositori aktifitas operasional.
  final OperationalRepository repository;

  @override
  Future<Either<Failure, OperationalResult>> call(
    GetOperationalsParams params,
  ) {
    return repository.getOperationals(params);
  }
}
