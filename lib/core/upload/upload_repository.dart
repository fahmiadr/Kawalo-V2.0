import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';

/// Reports upload progress as a fraction between 0 and 1.
typedef UploadProgress = void Function(double fraction);

/// Sends local files to the API upload endpoint and returns the public URL that
/// is stored in `photos[]`, `guest_photo` or `feed_file`.
///
/// Images are compressed to WebP (quality 90 to 100, at most 150 KB) before
/// they leave the device; documents are sent as they are within the size limit.
abstract interface class UploadRepository {
  /// Compresses [file] to WebP and uploads it.
  Future<Either<Failure, String>> uploadImage(
    AppMediaFile file, {
    UploadProgress? onProgress,
  });

  /// Uploads a document (pdf, doc, docx, xls, xlsx, txt) without transforming it.
  Future<Either<Failure, String>> uploadDocument(
    AppMediaFile file, {
    UploadProgress? onProgress,
  });
}
