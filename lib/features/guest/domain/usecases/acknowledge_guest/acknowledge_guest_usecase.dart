import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/acknowledge_guest/acknowledge_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/acknowledge_guest_data.dart';

/// Confirms a guest visit after checking the id format and who may confirm it.
class AcknowledgeGuestUseCase
    implements UseCase<GuestItemEntity, AcknowledgeGuestParams> {
  /// Creates an [AcknowledgeGuestUseCase].
  const AcknowledgeGuestUseCase(this.repository);

  /// Guest repository.
  final GuestRepository repository;

  @override
  Future<Either<Failure, GuestItemEntity>> call(
    AcknowledgeGuestParams params,
  ) async {
    if (!params.isValidId) {
      return const Left(
        ValidationFailure(
          'ID tamu wajib diisi dan memiliki format yang valid.',
        ),
      );
    }

    if (!params.isAuthorized) {
      return const Left(
        ForbiddenFailure(
          'Anda tidak memiliki izin untuk mengonfirmasi kunjungan tamu ini.',
        ),
      );
    }

    return await repository.acknowledgeGuest(
      AcknowledgeGuestData(
        id: params.id,
        qrUid: params.qrUid,
        cancelToken: params.cancelToken,
      ),
    );
  }
}
