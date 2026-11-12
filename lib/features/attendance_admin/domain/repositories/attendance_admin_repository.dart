import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/attendance_setting_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/face_photo_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/manual_request_entity.dart';

abstract class AttendanceAdminRepository {
  Future<Either<Failure, List<ManualRequestEntity>>> getManualRequests({
    required ManualRequestStatus status,
    required int limit,
    required int offset,
  });

  /// [approve] false rejects. [note] is optional and trimmed by the server.
  Future<Either<Failure, void>> decideManualRequest({
    required String id,
    required bool approve,
    String? note,
  });

  Future<Either<Failure, List<FacePhotoEntity>>> getFacePhotos(String email);

  /// Local file path of the downloaded photo; call [discardPhoto] when done.
  Future<Either<Failure, String>> downloadFacePhoto({
    required String email,
    required String photoId,
  });

  Future<void> discardPhoto(String path);

  Future<Either<Failure, AttendanceSettingEntity>> getSetting();

  /// A null [percent] restores the server default.
  Future<Either<Failure, AttendanceSettingEntity>> saveSetting(int? percent);
}
