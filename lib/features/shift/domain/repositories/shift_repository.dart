import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/shift/domain/entities/shift_entity.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_input.dart';

/// Online-only: there is no offline cache for shifts.
abstract interface class ShiftRepository {
  /// Active shifts of the group, ordered by start time.
  Future<Either<Failure, List<ShiftEntity>>> getShifts();

  /// Fails with status 409 when the name is taken.
  Future<Either<Failure, ShiftEntity>> createShift(ShiftInput input);

  /// Fails with status 409 when the name is taken.
  Future<Either<Failure, ShiftEntity>> updateShift(
    String uid,
    ShiftInput input,
  );

  /// Fails with status 409 while upcoming schedules still use the shift.
  Future<Either<Failure, void>> deleteShift(String uid);
}
