import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads biometric photos from admin-only endpoints through [ApiClient]
/// (the endpoints need the Authorization header, so a plain image URL cannot
/// work) into a temporary file the image viewer can open.
///
/// Photos are never cached: callers must [discard] the file once the viewer
/// closes so face images do not linger on disk.
class AuthenticatedPhotoFetcher {
  AuthenticatedPhotoFetcher({
    required ApiClient apiClient,
    Future<Directory> Function() temporaryDirectory = getTemporaryDirectory,
  }) : _apiClient = apiClient,
       _temporaryDirectory = temporaryDirectory;

  final ApiClient _apiClient;
  final Future<Directory> Function() _temporaryDirectory;

  /// [path] is relative to the API base (for example `/v1/attendance/9/photo`);
  /// [name] only needs to be unique per photo.
  Future<Either<Failure, String>> fetch(
    String path, {
    required String name,
  }) async {
    try {
      final root = await _temporaryDirectory();
      final directory = Directory('${root.path}/biometric_photos');
      await directory.create(recursive: true);
      final safeName = name.replaceAll(RegExp('[^A-Za-z0-9_-]'), '_');
      final file = '${directory.path}/$safeName.jpg';
      await _apiClient.dio.download(path, file);
      return Right(file);
    } on Object catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  Future<void> discard(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) await file.delete();
    } on Object catch (_) {
      // The OS clears the temporary directory eventually.
    }
  }
}
