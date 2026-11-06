import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/features/guest/data/datasources/guest_local_data_source.dart';
import 'package:kawalo_mobile/features/guest/data/datasources/guest_remote_data_source.dart';
import 'package:kawalo_mobile/features/guest/data/mappers/guest_mapper.dart';
import 'package:kawalo_mobile/features/guest/data/mappers/master_guest_type_mapper.dart';
import 'package:kawalo_mobile/features/guest/data/models/checkout_guest_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/create_guest_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/delete_batch_guest_request_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_id_params_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_query_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/update_guest_model.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/master_guest_type_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/checkout_guest_data.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/create_guest_data.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/delete_batch_result.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/get_guests_params.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/guest_result.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/update_guest_data.dart';

/// Implementasi konkret dari [GuestRepository] yang berkomunikasi
/// dengan remote data source dan mengelola fallback cache lokal saat offline.
///
/// Selaras 100% dengan kontrak endpoint backend `GET /v1/guests` (`GetGuestsQueryDto`).
class GuestRepositoryImpl implements GuestRepository {
  /// Membuat instance [GuestRepositoryImpl].
  const GuestRepositoryImpl({
    required this.remoteDataSource,
    this.localDataSource,
    this.syncStorageService,
    this.networkInfo,
  });

  /// Sumber data tamu jarak jauh (bisa dummy atau REST API).
  final GuestRemoteDataSource remoteDataSource;

  /// Sumber data tamu lokal untuk mode offline dan caching.
  final GuestLocalDataSource? localDataSource;

  /// Layanan persistensi waktu sinkronisasi.
  final SyncStorageService? syncStorageService;

  /// Utilitas pengecekan konektivitas jaringan perangkat.
  final NetworkInfo? networkInfo;

  @override
  Future<Either<Failure, GuestResult>> getGuests(
    GetGuestsParams params,
  ) async {
    // 1. Guard Offline: Jika bukan refresh, dilarang memicu remote fetch jika
    // perangkat sedang offline. Langsung ambil dari local cache seketika.
    if (!params.isRefresh) {
      final isConnected =
          await (networkInfo?.isConnected ?? Future.value(true));
      if (!isConnected) {
        if (localDataSource != null) {
          final cached = await localDataSource!.getCachedGuests(
            search: params.search,
            startDate: params.startDate,
            endDate: params.endDate,
            createdBy: params.createdBy,
          );
          return Right(
            GuestResult(
              items: GuestMapper.toEntityList(cached),
              isFromCache: true,
            ),
          );
        }
        return const Left(NoInternetFailure.offlineNoStorage());
      }
    }

    // 2. Mode Online atau Pull-to-Refresh: Lakukan remote fetch ke server
    // (pull-to-refresh selalu mencoba ke remote meskipun sedang offline).
    try {
      final query = GuestQueryModel(
        search: params.search,
        limit: params.limit,
        offset: params.offset,
        startDate: params.startDate,
        endDate: params.endDate,
        createdBy: params.createdBy,
      );

      final guests = await remoteDataSource.getGuests(
        query: query,
        cancelToken: params.cancelToken,
      );

      // Simpan data ke cache HANYA jika bukan rentang kustom
      if (localDataSource != null && guests.isNotEmpty) {
        await localDataSource!.cacheGuests(guests);

        // Terapkan Cache Invalidation & Eviction: Rolling Window 30 Hari
        final thirtyDaysAgo =
            DateTime.now().subtract(AppConstants.cacheRetentionDuration);
        await localDataSource!.deleteOlderThan(thirtyDaysAgo);
      }

      // Catat waktu sukses sinkronisasi server HANYA ketika remote berhasil
      await (syncStorageService ?? SyncStorageService.singleton())
          .saveLastSync(AppConstants.syncKeyGuest, DateTime.now());

      return Right(
        GuestResult(
          items: GuestMapper.toEntityList(guests),
        ),
      );
    } on AppException catch (e) {
      if (e is RequestCancelledException) {
        return const Left(RequestCancelledFailure());
      }
      if (localDataSource != null && _canFallbackToCache(e)) {
        final cached = await localDataSource!.getCachedGuests(
          search: params.search,
          startDate: params.startDate,
          endDate: params.endDate,
          createdBy: params.createdBy,
        );
        return Right(
          GuestResult(
            items: GuestMapper.toEntityList(cached),
            isFromCache: true,
          ),
        );
      }
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    } on Exception catch (e) {
      if (localDataSource != null) {
        final cached = await localDataSource!.getCachedGuests(
          search: params.search,
          startDate: params.startDate,
          endDate: params.endDate,
          createdBy: params.createdBy,
        );
        return Right(
          GuestResult(
            items: GuestMapper.toEntityList(cached),
            isFromCache: true,
          ),
        );
      }
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, GuestItemEntity>> createGuest(
    CreateGuestData data,
  ) async {
    // 1. Guard Jaringan: Operasi pembuatan data membutuhkan koneksi aktif
    final isConnected = await (networkInfo?.isConnected ?? Future.value(true));
    if (!isConnected) {
      return const Left(NoInternetFailure());
    }

    // 2. Mode Online: Eksekusi pengiriman data ke remote server
    try {
      final model = CreateGuestModel(
        guestName: data.guestName,
        guestDestination: data.guestDestination,
        guestType: data.guestType,
        guestPurpose: data.guestPurpose,
        guestNumber: data.guestNumber,
        guestIdentity: data.guestIdentity,
        guestIdentityType: data.guestIdentityType,
        guestAddress: data.guestAddress,
        guestToUserEmail: data.guestToUserEmail,
        guestPhoto: data.guestPhoto,
        guestDt: data.guestDt,
      );
      final createdModel = await remoteDataSource.createGuest(
        data: model,
        cancelToken: data.cancelToken,
      );

      // 3. Sinkronisasi Cache Lokal: Simpan data baru ke Isar cache jika
      // tersedia.
      if (localDataSource != null) {
        try {
          await localDataSource!.cacheGuests([createdModel]);
        } on Object catch (_) {
          // Best-effort: kegagalan I/O cache lokal tidak membatalkan
          // konfirmasi sukses dari server yang sudah otoritatif.
        }
      }

      final entity = GuestMapper.toEntity(createdModel);
      return Right(entity);
    } on AppException catch (e) {
      if (e is RequestCancelledException) {
        return const Left(RequestCancelledFailure());
      }
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, GuestItemEntity>> updateGuest(
    UpdateGuestData data,
  ) async {
    // 1. Guard Jaringan: Operasi pembaruan data membutuhkan koneksi aktif
    final isConnected = await (networkInfo?.isConnected ?? Future.value(true));
    if (!isConnected) {
      return const Left(NoInternetFailure());
    }

    // 2. Mode Online: Eksekusi pengiriman data pembaruan ke remote server
    try {
      final paramsModel = GuestIdParamsModel(id: data.id);
      final model = UpdateGuestModel(
        guestName: data.guestName,
        guestDestination: data.guestDestination,
        guestType: data.guestType,
        guestPurpose: data.guestPurpose,
        guestNumber: data.guestNumber,
        guestIdentity: data.guestIdentity,
        guestIdentityType: data.guestIdentityType,
        guestAddress: data.guestAddress,
        guestToUserEmail: data.guestToUserEmail,
        guestPhoto: data.guestPhoto,
        includeNulls: data.includeNulls,
      );

      final updatedModel = await remoteDataSource.updateGuest(
        params: paramsModel,
        data: model,
        cancelToken: data.cancelToken,
      );

      // 3. Sinkronisasi Cache Lokal: Simpan data terupdate ke Isar cache
      // jika tersedia.
      if (localDataSource != null) {
        try {
          await localDataSource!.cacheGuests([updatedModel]);
        } on Object catch (_) {
          // Best-effort: kegagalan I/O cache lokal tidak membatalkan
          // konfirmasi sukses dari server yang sudah otoritatif.
        }
      }

      final entity = GuestMapper.toEntity(updatedModel);
      return Right(entity);
    } on AppException catch (e) {
      if (e is RequestCancelledException) {
        return const Left(RequestCancelledFailure());
      }
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, GuestItemEntity>> checkoutGuest(
    CheckoutGuestData data,
  ) async {
    // 1. Guard Jaringan: Operasi check-out tamu membutuhkan koneksi aktif
    final isConnected = await (networkInfo?.isConnected ?? Future.value(true));
    if (!isConnected) {
      return const Left(NoInternetFailure());
    }

    // 2. Mode Online: Eksekusi pengiriman request check-out ke remote server
    try {
      final paramsModel = GuestIdParamsModel(id: data.id);
      final model = CheckoutGuestModel(qrUid: data.qrUid);

      final updatedModel = await remoteDataSource.checkoutGuest(
        params: paramsModel,
        data: model,
        cancelToken: data.cancelToken,
      );

      // 3. Sinkronisasi Cache Lokal: Simpan data terupdate ke Isar cache
      // jika tersedia.
      if (localDataSource != null) {
        try {
          await localDataSource!.cacheGuests([updatedModel]);
        } on Object catch (_) {
          // Best-effort: kegagalan I/O cache lokal tidak membatalkan
          // konfirmasi sukses dari server yang sudah otoritatif.
        }
      }

      final entity = GuestMapper.toEntity(updatedModel);
      return Right(entity);
    } on AppException catch (e) {
      if (e is RequestCancelledException) {
        return const Left(RequestCancelledFailure());
      }
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<MasterGuestTypeEntity>>> getMasterGuestTypes({
    AppCancellationToken? cancelToken,
  }) async {
    // 1. Guard Jaringan: Operasi pengambilan data master membutuhkan
    // koneksi aktif.
    final isConnected = await (networkInfo?.isConnected ?? Future.value(true));
    if (!isConnected) {
      return const Left(NoInternetFailure());
    }

    try {
      final models = await remoteDataSource.getMasterGuestTypes(
        cancelToken: cancelToken,
      );
      final entities = MasterGuestTypeMapper.toEntityList(models);
      return Right(entities);
    } on Exception catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGuest({
    required String id,
    AppCancellationToken? cancelToken,
  }) async {
    // 1. Guard Jaringan: Operasi penghapusan data membutuhkan koneksi aktif
    final isConnected = await (networkInfo?.isConnected ?? Future.value(true));
    if (!isConnected) {
      return const Left(NoInternetFailure());
    }

    // 2. Mode Online: Eksekusi penghapusan di remote server
    try {
      final params = GuestIdParamsModel(id: id);
      await remoteDataSource.deleteGuest(
        params: params,
        cancelToken: cancelToken,
      );

      // 3. Sinkronisasi Cache Lokal: Best-effort cache eviction jika remote
      // berhasil.
      if (localDataSource != null) {
        try {
          await localDataSource!.deleteGuest(id);
        } on Object catch (_) {
          // Best-effort: kegagalan I/O cache lokal tidak membatalkan
          // konfirmasi sukses dari server yang sudah otoritatif.
        }
      }

      return const Right(null);
    } on AppException catch (e) {
      if (e is RequestCancelledException) {
        return const Left(RequestCancelledFailure());
      }
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, DeleteBatchResult>> deleteBatchGuests({
    required List<String> ids,
    AppCancellationToken? cancelToken,
  }) async {
    // 1. Guard Jaringan: Operasi batch delete membutuhkan koneksi aktif
    final isConnected = await (networkInfo?.isConnected ?? Future.value(true));
    if (!isConnected) {
      return const Left(NoInternetFailure());
    }

    // 2. Mode Online: Eksekusi batch delete di remote server
    try {
      final params = DeleteBatchGuestRequestModel(ids: ids);
      final response = await remoteDataSource.deleteBatchGuests(
        params: params,
        cancelToken: cancelToken,
      );

      // 3. Sinkronisasi Cache Lokal: Best-effort cache eviction jika remote
      // berhasil.
      if (localDataSource != null) {
        try {
          await localDataSource!.deleteBatchGuests(ids);
        } on Object catch (_) {
          // Best-effort: kegagalan I/O cache lokal tidak membatalkan
          // konfirmasi sukses dari server yang sudah otoritatif.
        }
      }

      return Right(GuestMapper.toDeleteBatchResult(response));
    } on AppException catch (e) {
      if (e is RequestCancelledException) {
        return const Left(RequestCancelledFailure());
      }
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  bool _canFallbackToCache(AppException e) {
    if (e is RequestCancelledException || e is AuthException) {
      return false;
    }
    return true;
  }
}
