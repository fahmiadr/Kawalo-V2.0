import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/repositories/cached_remote_fetch.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/features/information/data/datasources/information_local_data_source.dart';
import 'package:kawalo_mobile/features/information/data/datasources/information_remote_data_source.dart';
import 'package:kawalo_mobile/features/information/data/mappers/information_mapper.dart';
import 'package:kawalo_mobile/features/information/data/models/create_information_model.dart';
import 'package:kawalo_mobile/features/information/data/models/delete_batch_information_request_model.dart';
import 'package:kawalo_mobile/features/information/data/models/information_id_params_model.dart';
import 'package:kawalo_mobile/features/information/data/models/information_model.dart';
import 'package:kawalo_mobile/features/information/data/models/information_query_model.dart';
import 'package:kawalo_mobile/features/information/data/models/update_information_model.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/repositories/information_repository.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/create_information_data.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/delete_batch_result.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/get_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/information_result.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/update_information_data.dart';

/// Implementasi konkret repositori informasi / feed yang mengelola
/// remote data source, fallback cache lokal saat offline, dan transparansi
/// sumber data.
///
/// Selaras 100% dengan kontrak endpoint backend `GET /v1/information`
/// (`GetInformationQueryDto`).
class InformationRepositoryImpl implements InformationRepository {
  /// Membuat instance [InformationRepositoryImpl].
  const InformationRepositoryImpl({
    required this.remoteDataSource,
    this.localDataSource,
    this.syncStorageService,
    this.networkInfo,
  });

  /// Sumber data remote API.
  final InformationRemoteDataSource remoteDataSource;

  /// Sumber data lokal untuk caching dan offline fallback.
  final InformationLocalDataSource? localDataSource;

  /// Layanan persistensi waktu sinkronisasi.
  final SyncStorageService? syncStorageService;

  /// Layanan pengecekan status konektivitas jaringan.
  final NetworkInfo? networkInfo;

  @override
  Future<Either<Failure, InformationResult>> getInformation(
    GetInformationParams params,
  ) {
    final local = localDataSource;
    return fetchRemoteWithCacheFallback<InformationModel, InformationResult>(
      isRefresh: params.isRefresh,
      networkInfo: networkInfo,
      syncStorageService: syncStorageService,
      syncKey: AppConstants.syncKeyInformation,
      fetchRemote: () => remoteDataSource.getInformation(
        query: InformationQueryModel(
          search: params.search,
          limit: params.limit,
          offset: params.offset,
          startDate: params.startDate,
          endDate: params.endDate,
          createdBy: params.createdBy,
        ),
        cancelToken: params.cancelToken,
      ),
      toResult: (models, {required isFromCache}) => InformationResult(
        items: InformationMapper.toEntityList(models),
        isFromCache: isFromCache,
      ),
      cache: local == null
          ? null
          : CacheOps(
              read: () => local.getCachedInformation(
                search: params.search,
                startDate: params.startDate,
                endDate: params.endDate,
                createdBy: params.createdBy,
              ),
              write: local.cacheInformation,
              deleteOlderThan: local.deleteOlderThan,
            ),
    );
  }

  @override
  Future<Either<Failure, InformationItemEntity>> createInformation(
    CreateInformationData data,
  ) async {
    // 1. Guard Jaringan: Operasi pembuatan data membutuhkan koneksi aktif
    final isConnected = await (networkInfo?.isConnected ?? Future.value(true));
    if (!isConnected) {
      return const Left(NoInternetFailure());
    }

    // 2. Mode Online: Eksekusi pengiriman data ke remote server
    try {
      final model = CreateInformationModel(
        title: data.title,
        text: data.text,
        feedFile: data.feedFile,
        photos: data.photos,
        feedType: data.feedType,
        eventLocation: data.eventLocation,
        glat: data.glat,
        glong: data.glong,
      );

      final createdModel = await remoteDataSource.createInformation(
        data: model,
        cancelToken: data.cancelToken,
      );

      // 3. Sinkronisasi Cache Lokal: Simpan data baru ke Isar cache jika
      // tersedia.
      final local = localDataSource;
      await bestEffortCache(
        local == null ? null : () => local.cacheInformation([createdModel]),
      );

      final entity = InformationMapper.toEntity(createdModel);
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
  Future<Either<Failure, InformationItemEntity>> updateInformation(
    UpdateInformationData data,
  ) async {
    // 1. Guard Jaringan: Operasi pembaruan data membutuhkan koneksi aktif
    final isConnected = await (networkInfo?.isConnected ?? Future.value(true));
    if (!isConnected) {
      return const Left(NoInternetFailure());
    }

    // 2. Mode Online: Eksekusi pengiriman data pembaruan ke remote server
    try {
      final paramsModel = InformationIdParamsModel(id: data.id);
      final model = UpdateInformationModel(
        title: data.title,
        text: data.text,
        feedFile: data.feedFile,
        photos: data.photos,
        feedType: data.feedType,
        eventLocation: data.eventLocation,
        glat: data.glat,
        glong: data.glong,
        includeNulls: data.includeNulls,
      );

      final updatedModel = await remoteDataSource.updateInformation(
        params: paramsModel,
        data: model,
        cancelToken: data.cancelToken,
      );

      // 3. Sinkronisasi Cache Lokal: Simpan data terupdate ke Isar cache
      // jika tersedia.
      final local = localDataSource;
      await bestEffortCache(
        local == null ? null : () => local.cacheInformation([updatedModel]),
      );

      final entity = InformationMapper.toEntity(updatedModel);
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
  Future<Either<Failure, void>> deleteInformation({
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
      final params = InformationIdParamsModel(id: id);
      await remoteDataSource.deleteInformation(
        params: params,
        cancelToken: cancelToken,
      );

      // 3. Sinkronisasi Cache Lokal: Best-effort cache eviction jika remote
      // berhasil.
      final local = localDataSource;
      await bestEffortCache(
        local == null ? null : () => local.deleteInformation(id),
      );

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
  Future<Either<Failure, DeleteBatchResult>> deleteBatchInformation({
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
      final params = DeleteBatchInformationRequestModel(ids: ids);
      final response = await remoteDataSource.deleteBatchInformation(
        params: params,
        cancelToken: cancelToken,
      );

      // 3. Sinkronisasi Cache Lokal: Best-effort cache eviction jika remote
      // berhasil.
      final local = localDataSource;
      await bestEffortCache(
        local == null ? null : () => local.deleteBatchInformation(ids),
      );

      return Right(InformationMapper.toDeleteBatchResult(response));
    } on AppException catch (e) {
      if (e is RequestCancelledException) {
        return const Left(RequestCancelledFailure());
      }
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }
}
