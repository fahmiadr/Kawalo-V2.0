import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/create_information_data.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/delete_batch_result.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/get_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/information_result.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/update_information_data.dart';

/// Kontrak repositori domain untuk modul data informasi / feed dengan dukungan
/// transparansi sumber data (cache offline vs server remote).
abstract class InformationRepository {
  /// Mengambil daftar informasi / feed dengan filter pencarian, rentang tanggal,
  /// filter pembuat, pagination, dan transparansi sumber data.
  Future<Either<Failure, InformationResult>> getInformation(
    GetInformationParams params,
  );

  /// Membuat data informasi / feed baru di server backend.
  ///
  /// Menerima [data] yang berisi payload feed dan opsi token pembatalan.
  /// Mengembalikan [InformationItemEntity] yang berhasil dibuat.
  Future<Either<Failure, InformationItemEntity>> createInformation(
    CreateInformationData data,
  );

  /// Memperbarui data informasi / feed yang sudah ada di server backend.
  ///
  /// Menerima [data] yang berisi perubahan data dan opsi token pembatalan.
  /// Mengembalikan [InformationItemEntity] yang berhasil diperbarui.
  Future<Either<Failure, InformationItemEntity>> updateInformation(
    UpdateInformationData data,
  );

  /// Menghapus data informasi / feed berdasarkan [id].
  ///
  /// [id] adalah identifier unik feed yang berupa string numerik.
  /// [cancelToken] opsional untuk pembatalan request.
  Future<Either<Failure, void>> deleteInformation({
    required String id,
    AppCancellationToken? cancelToken,
  });

  /// Menghapus sekumpulan data informasi / feed berdasarkan daftar [ids].
  ///
  /// Mengembalikan [DeleteBatchResult] yang berisi jumlah data terhapus.
  /// [cancelToken] opsional untuk pembatalan request.
  Future<Either<Failure, DeleteBatchResult>> deleteBatchInformation({
    required List<String> ids,
    AppCancellationToken? cancelToken,
  });
}
