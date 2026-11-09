import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/repositories/cached_remote_fetch.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/features/incident/data/datasources/incident_local_data_source.dart';
import 'package:kawalo_mobile/features/incident/data/datasources/incident_remote_data_source.dart';
import 'package:kawalo_mobile/features/incident/data/mappers/incident_mapper.dart';
import 'package:kawalo_mobile/features/incident/data/mappers/incident_reply_mapper.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_model.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_reply_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_stream_event.dart';
import 'package:kawalo_mobile/features/incident/domain/repositories/incident_repository.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/create_incident_data.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_detail_result.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_list_result.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_query_params.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/post_incident_reply_data.dart';

/// Implementasi konkret dari [IncidentRepository] yang menjembatani Domain
/// Layer dengan remote API datasource dan SSE streaming.
///
/// Only the incident list is cached for offline reading; detail, replies and
/// every mutation still require a live connection.
class IncidentRepositoryImpl implements IncidentRepository {
  /// Membuat instance [IncidentRepositoryImpl].
  const IncidentRepositoryImpl({
    required this.remoteDataSource,
    required this.syncStorageService,
    this.localDataSource,
    this.networkInfo,
  });

  /// Sumber data remote API.
  final IncidentRemoteDataSource remoteDataSource;

  /// Sumber data lokal untuk cache daftar insiden (opsional).
  final IncidentLocalDataSource? localDataSource;

  /// Layanan persistensi waktu sinkronisasi.
  final SyncStorageService syncStorageService;

  /// Utilitas pengecekan konektivitas jaringan perangkat (opsional).
  final NetworkInfo? networkInfo;

  @override
  Future<Either<Failure, IncidentListResult>> getIncidents(
    IncidentQueryParams params,
  ) {
    final local = localDataSource;
    return fetchRemoteWithCacheFallback<IncidentModel, IncidentListResult>(
      isRefresh: params.isRefresh,
      networkInfo: networkInfo,
      syncStorageService: syncStorageService,
      syncKey: AppConstants.syncKeyIncident,
      fetchRemote: () => remoteDataSource.getIncidents(
        query: IncidentMapper.toQueryModel(params),
        cancelToken: params.cancelToken,
      ),
      // The cache is not paginated: serving it for a later page would repeat
      // the first page, so only offset 0 reads from it.
      toResult: (models, {required isFromCache}) => IncidentListResult(
        items: isFromCache && (params.offset ?? 0) > 0
            ? const []
            : IncidentMapper.toEntityList(models),
        isFromCache: isFromCache,
      ),
      cache: local == null
          ? null
          : CacheOps(
              read: () => local.getCachedIncidents(
                groupId: params.groupId,
                status: params.status?.value,
                search: params.search,
                startDate: params.startDate,
                endDate: params.endDate,
              ),
              write: local.cacheIncidents,
              deleteOlderThan: local.deleteOlderThan,
            ),
    );
  }

  @override
  Future<Either<Failure, IncidentDetailResult>> getIncidentDetail({
    required String incidentId,
    AppCancellationToken? cancelToken,
  }) async {
    final isConnected = await (networkInfo?.isConnected ?? Future.value(true));
    if (!isConnected) {
      return const Left(NoInternetFailure());
    }

    try {
      final model = await remoteDataSource.getIncidentDetail(
        incidentId: incidentId,
        cancelToken: cancelToken,
      );
      return Right(IncidentMapper.toDetailResult(model));
    } on AppException catch (e) {
      if (e is RequestCancelledException) {
        return const Left(RequestCancelledFailure());
      }
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    } on Object catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, IncidentEntity>> createIncident(
    CreateIncidentData data,
  ) async {
    // 1. Guard Jaringan: Operasi pembuatan laporan membutuhkan koneksi aktif
    final isConnected = await (networkInfo?.isConnected ?? Future.value(true));
    if (!isConnected) {
      return const Left(NoInternetFailure());
    }

    // 2. Mode Online: Eksekusi pengiriman data ke server backend
    try {
      final createModel = IncidentMapper.toCreateModel(data);
      final model = await remoteDataSource.createIncident(
        data: createModel,
        cancelToken: data.cancelToken,
      );
      return Right(IncidentMapper.toEntity(model));
    } on AppException catch (e) {
      if (e is RequestCancelledException) {
        return const Left(RequestCancelledFailure());
      }
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    } on Object catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  @override
  Stream<Either<Failure, IncidentStreamEvent>> watchIncidentReplies({
    required String incidentId,
    String? lastEventId,
    AppCancellationToken? cancelToken,
  }) async* {
    try {
      final sseStream = remoteDataSource.watchIncidentStream(
        incidentId: incidentId,
        lastEventId: lastEventId,
        cancelToken: cancelToken,
      );

      await for (final message in sseStream) {
        // Sinyal penanganan replay buffer overflow dari backend
        if (message.event == 'sync_required') {
          try {
            final detailModel = await remoteDataSource.getIncidentDetail(
              incidentId: incidentId,
              cancelToken: cancelToken,
            );
            final detailResult = IncidentMapper.toDetailResult(detailModel);
            yield Right(
              IncidentResyncedStreamEvent(
                incident: detailResult.incident,
                replies: detailResult.replies,
              ),
            );
          } on Object catch (e) {
            yield Left(NetworkErrorHandler.handleExceptionToFailure(e));
          }
          continue;
        }

        final domainEvent = IncidentReplyMapper.parseSseMessage(message);
        if (domainEvent != null) {
          yield Right(domainEvent);
        }
      }
    } on AppException catch (e) {
      if (e is ServerException && e.statusCode == 410) {
        // HTTP 410 Gone: Replay buffer overflow, sinkronisasi ulang seluruh
        // thread
        try {
          final detailModel = await remoteDataSource.getIncidentDetail(
            incidentId: incidentId,
            cancelToken: cancelToken,
          );
          final detailResult = IncidentMapper.toDetailResult(detailModel);
          yield Right(
            IncidentResyncedStreamEvent(
              incident: detailResult.incident,
              replies: detailResult.replies,
            ),
          );
        } on Object catch (detailErr) {
          yield Left(NetworkErrorHandler.handleExceptionToFailure(detailErr));
        }
      } else {
        yield Left(NetworkErrorHandler.handleExceptionToFailure(e));
      }
    } on Object catch (e) {
      yield Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, IncidentReplyEntity>> postIncidentReply(
    PostIncidentReplyData data,
  ) async {
    final isConnected = await (networkInfo?.isConnected ?? Future.value(true));
    if (!isConnected) {
      return const Left(NoInternetFailure());
    }

    try {
      final replyModel = IncidentReplyMapper.toPostModel(data);
      final model = await remoteDataSource.postIncidentReply(
        incidentId: data.incidentId,
        data: replyModel,
        cancelToken: data.cancelToken,
      );
      return Right(IncidentReplyMapper.toEntity(model));
    } on AppException catch (e) {
      if (e is RequestCancelledException) {
        return const Left(RequestCancelledFailure());
      }
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    } on Object catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, IncidentEntity>> resolveIncident({
    required String incidentId,
    AppCancellationToken? cancelToken,
  }) async {
    final isConnected = await (networkInfo?.isConnected ?? Future.value(true));
    if (!isConnected) {
      return const Left(NoInternetFailure());
    }

    try {
      final model = await remoteDataSource.resolveIncident(
        incidentId: incidentId,
        cancelToken: cancelToken,
      );
      return Right(IncidentMapper.toEntity(model));
    } on AppException catch (e) {
      if (e is RequestCancelledException) {
        return const Left(RequestCancelledFailure());
      }
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    } on Object catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteIncident({
    required String incidentId,
    AppCancellationToken? cancelToken,
  }) async {
    final isConnected = await (networkInfo?.isConnected ?? Future.value(true));
    if (!isConnected) {
      return const Left(NoInternetFailure());
    }

    try {
      await remoteDataSource.deleteIncident(
        incidentId: incidentId,
        cancelToken: cancelToken,
      );
      return const Right(null);
    } on AppException catch (e) {
      if (e is RequestCancelledException) {
        return const Left(RequestCancelledFailure());
      }
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    } on Object catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }
}
