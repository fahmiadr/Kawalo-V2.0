import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/features/attendance/photo/authenticated_photo_fetcher.dart';
import 'package:kawalo_mobile/features/attendance_admin/data/datasources/attendance_admin_remote_data_source.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/attendance_location_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/attendance_setting_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/face_photo_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/manual_request_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/repositories/attendance_admin_repository.dart';

class AttendanceAdminRepositoryImpl implements AttendanceAdminRepository {
  const AttendanceAdminRepositoryImpl({
    required this.remoteDataSource,
    required this.photoFetcher,
  });

  final AttendanceAdminRemoteDataSource remoteDataSource;
  final AuthenticatedPhotoFetcher photoFetcher;

  @override
  Future<Either<Failure, List<ManualRequestEntity>>> getManualRequests({
    required ManualRequestStatus status,
    required int limit,
    required int offset,
  }) => _guard(() async {
    final models = await remoteDataSource.getManualRequests(
      status: status,
      limit: limit,
      offset: offset,
    );
    return models.map((m) => m.toEntity()).toList(growable: false);
  });

  @override
  Future<Either<Failure, void>> decideManualRequest({
    required String id,
    required bool approve,
    String? note,
  }) => _guard(
    () => remoteDataSource.decide(id: id, approve: approve, note: note),
  );

  @override
  Future<Either<Failure, List<FacePhotoEntity>>> getFacePhotos(String email) =>
      _guard(() => remoteDataSource.getFacePhotos(email));

  @override
  Future<Either<Failure, String>> downloadFacePhoto({
    required String email,
    required String photoId,
  }) => photoFetcher.fetch(
    '/v1/faces/${Uri.encodeComponent(email)}/photos/'
    '${Uri.encodeComponent(photoId)}',
    name: 'face_${email}_$photoId',
  );

  @override
  Future<void> discardPhoto(String path) => photoFetcher.discard(path);

  @override
  Future<Either<Failure, AttendanceSettingEntity>> getSetting() =>
      _guard(() async => (await remoteDataSource.getSetting()).toEntity());

  @override
  Future<Either<Failure, AttendanceSettingEntity>> saveSetting(int? percent) =>
      _guard(
        () async => (await remoteDataSource.saveSetting(percent)).toEntity(),
      );

  @override
  Future<Either<Failure, AttendanceLocationEntity>> getLocation() =>
      _guard(() async => (await remoteDataSource.getLocation()).toEntity());

  @override
  Future<Either<Failure, AttendanceLocationEntity>> saveLocation({
    required double latitude,
    required double longitude,
    required int radius,
    String? locationName,
  }) => _guard(
    () async => (await remoteDataSource.saveLocation(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      locationName: locationName,
    )).toEntity(),
  );

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on Object catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }
}
