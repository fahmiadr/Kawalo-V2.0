import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/operational/domain/value_objects/get_operationals_params.dart';
import 'package:kawalo_mobile/features/operational/domain/value_objects/operational_result.dart';

/// Kontrak domain repositori untuk modul aktifitas operasional tenaga kerja
/// dengan transparansi sumber data (cache offline vs server remote).
abstract class OperationalRepository {
  /// Mengambil daftar personil tenaga kerja operasional dengan filter opsional
  /// dan transparansi sumber data.
  Future<Either<Failure, OperationalResult>> getOperationals(
    GetOperationalsParams params,
  );
}
