import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/features/attendance/data/datasources/attendance_check_remote_data_source.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_check_result.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_slot.dart';
import 'package:kawalo_mobile/features/attendance/domain/repositories/attendance_check_repository.dart';
import 'package:kawalo_mobile/features/face/data/datasources/face_multipart.dart';
import 'package:kawalo_mobile/features/face/domain/repositories/face_repository.dart';

class AttendanceCheckRepositoryImpl implements AttendanceCheckRepository {
  const AttendanceCheckRepositoryImpl({required this.remoteDataSource});

  final AttendanceCheckRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, List<AttendanceSlot>>> getSlots(DateTime today) =>
      _guard(() => remoteDataSource.getSlots(today));

  @override
  Future<Either<Failure, AttendanceNonce>> issueNonce() =>
      _guard(remoteDataSource.issueNonce);

  @override
  Future<Either<Failure, AttendanceCheckResult>> submit({
    required Uint8List photo,
    required double latitude,
    required double longitude,
    required String nonce,
  }) => _guard(
    () => remoteDataSource.submit(
      photo: photo,
      latitude: latitude,
      longitude: longitude,
      nonce: nonce,
    ),
  );

  @override
  Future<Either<Failure, String>> requestManual({
    required ManualAttendanceReason reason,
    required double latitude,
    required double longitude,
    String? note,
  }) => _guard(
    () => remoteDataSource.requestManual(
      reason: reason,
      latitude: latitude,
      longitude: longitude,
      note: note,
    ),
  );

  static Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on ServerExceptionWithBody catch (e) {
      if (e.errorCode == FaceErrorCodes.notMatch) {
        final attempts = e.field('failed_attempts');
        final available = e.field('manual_request_available');
        return Left(
          FaceNotMatchFailure(
            e.message,
            failedAttempts: attempts is num ? attempts.toInt() : null,
            manualRequestAvailable: available is bool ? available : null,
          ),
        );
      }
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    } on FormatException {
      return const Left(
        ServerFailure('Respons server tidak valid. Silakan coba lagi.'),
      );
    } on Object catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }
}
