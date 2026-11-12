import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/features/face/data/datasources/face_remote_data_source.dart';
import 'package:kawalo_mobile/features/face/domain/entities/face_status.dart';
import 'package:kawalo_mobile/features/face/domain/repositories/face_repository.dart';

class FaceRepositoryImpl implements FaceRepository {
  const FaceRepositoryImpl({required this.remoteDataSource});

  final FaceRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, FaceStatus>> getStatus() =>
      _guard(remoteDataSource.getStatus);

  @override
  Future<Either<Failure, FaceRegistration>> register(
    List<Uint8List> photos, {
    bool replaceExisting = false,
  }) => _guard(() async {
    if (replaceExisting) await remoteDataSource.deleteMine();
    return await remoteDataSource.register(photos);
  });

  @override
  Future<Either<Failure, bool>> deleteMine() =>
      _guard(remoteDataSource.deleteMine);

  static Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on Object catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }
}
