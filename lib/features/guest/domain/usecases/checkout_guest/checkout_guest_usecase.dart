import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/checkout_guest/checkout_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/checkout_guest_data.dart';

/// Use case untuk melakukan check-out data tamu dari repositori.
///
/// Menerapkan pola GoF Command melalui abstraksi [UseCase],
/// mengisolasi logika validasi invariant dan otorisasi dari UI layer.
class CheckoutGuestUseCase
    implements UseCase<GuestItemEntity, CheckoutGuestParams> {
  /// Membuat instance [CheckoutGuestUseCase].
  const CheckoutGuestUseCase(this.repository);

  /// Kontrak repositori data tamu.
  final GuestRepository repository;

  @override
  Future<Either<Failure, GuestItemEntity>> call(
    CheckoutGuestParams params,
  ) async {
    // 1. Validasi Invariant Domain: ID wajib diisi dan sesuai format
    if (!params.isValidId) {
      return const Left(
        ValidationFailure(
          'ID tamu wajib diisi dan memiliki format yang valid.',
        ),
      );
    }

    // 2. Otorisasi Domain: Hanya ADMIN atau GUARD pada tamu yang belum keluar
    if (!params.isAuthorized) {
      return const Left(
        ForbiddenFailure(
          'Anda tidak memiliki izin untuk melakukan check-out tamu ini.',
        ),
      );
    }

    // 3. Delegasi ke Repositori
    return await repository.checkoutGuest(
      CheckoutGuestData(
        id: params.id,
        qrUid: params.qrUid,
        cancelToken: params.cancelToken,
      ),
    );
  }
}
