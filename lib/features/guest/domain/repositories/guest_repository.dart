import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/master_guest_type_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/checkout_guest_data.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/create_guest_data.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/delete_batch_result.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/get_guests_params.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/guest_result.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/update_guest_data.dart';

/// Kontrak repositori domain untuk modul data tamu.
abstract class GuestRepository {
  /// Mengambil daftar data tamu dengan filter pencarian, rentang waktu,
  /// dan pembuat data tamu opsional.
  Future<Either<Failure, GuestResult>> getGuests(GetGuestsParams params);

  /// Mendaftarkan tamu baru ke sistem backend.
  ///
  /// Menerima [data] yang berisi payload pendaftaran tamu.
  /// Mengembalikan [GuestItemEntity] yang berhasil dibuat.
  Future<Either<Failure, GuestItemEntity>> createGuest(CreateGuestData data);

  /// Memperbarui data tamu yang sudah ada ke sistem backend.
  ///
  /// Menerima [data] yang berisi payload pembaruan tamu.
  /// Mengembalikan [GuestItemEntity] terbaru dari server.
  Future<Either<Failure, GuestItemEntity>> updateGuest(UpdateGuestData data);

  /// Melakukan check-out tamu dari sistem backend.
  ///
  /// Menerima [data] yang berisi identifier tamu dan token pembatalan
  /// opsional. Mengembalikan [GuestItemEntity] terbaru yang telah diperbarui
  /// waktu keluarnya.
  Future<Either<Failure, GuestItemEntity>> checkoutGuest(
    CheckoutGuestData data,
  );

  /// Mengambil daftar master tipe tamu yang sah dari grup aktif.
  Future<Either<Failure, List<MasterGuestTypeEntity>>> getMasterGuestTypes({
    AppCancellationToken? cancelToken,
  });

  /// Menghapus data tamu berdasarkan [id].
  ///
  /// [id] adalah identifier unik data tamu yang berupa string numerik.
  /// [cancelToken] opsional untuk pembatalan request.
  Future<Either<Failure, void>> deleteGuest({
    required String id,
    AppCancellationToken? cancelToken,
  });

  /// Menghapus sekumpulan data tamu berdasarkan daftar [ids].
  ///
  /// Mengembalikan [DeleteBatchResult] yang berisi jumlah data terhapus.
  /// [cancelToken] opsional untuk pembatalan request.
  Future<Either<Failure, DeleteBatchResult>> deleteBatchGuests({
    required List<String> ids,
    AppCancellationToken? cancelToken,
  });
}
