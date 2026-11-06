import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/incident/data/datasources/incident_remote_data_source.dart';
import 'package:kawalo_mobile/features/incident/data/mappers/incident_mapper.dart';
import 'package:kawalo_mobile/features/incident/data/mappers/incident_reply_mapper.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_reply_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_stream_event.dart';
import 'package:kawalo_mobile/features/incident/domain/repositories/incident_repository.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/create_incident_data.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_detail_result.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_query_params.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/post_incident_reply_data.dart';

/// Implementasi konkret dari [IncidentRepository] yang menjembatani Domain
/// Layer dengan remote API datasource dan SSE streaming.
class IncidentRepositoryImpl implements IncidentRepository {
  /// Membuat instance [IncidentRepositoryImpl].
  const IncidentRepositoryImpl({
    required this.remoteDataSource,
    this.networkInfo,
  });

  /// Sumber data remote API.
  final IncidentRemoteDataSource remoteDataSource;

  /// Utilitas pengecekan konektivitas jaringan perangkat (opsional).
  final NetworkInfo? networkInfo;

  @override
  Future<Either<Failure, List<IncidentEntity>>> getIncidents(
    IncidentQueryParams params,
  ) async {
    final isConnected = await (networkInfo?.isConnected ?? Future.value(true));
    if (!isConnected) {
      return const Left(NoInternetFailure());
    }

    try {
      final queryModel = IncidentMapper.toQueryModel(params);
      final models = await remoteDataSource.getIncidents(
        query: queryModel,
        cancelToken: params.cancelToken,
      );
      return Right(IncidentMapper.toEntityList(models));
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
