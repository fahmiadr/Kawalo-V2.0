import 'dart:collection';
import 'dart:math' as math;

import 'package:kawalo_mobile/core/upload/upload_repository.dart';
import 'package:kawalo_mobile/features/incident/presentation/models/incident_media_item.dart';

/// Applies [change] to the photo with [id] in the owning cubit's state.
typedef IncidentPhotoPatcher =
    void Function(
      String id,
      IncidentMediaItem Function(IncidentMediaItem current) change,
    );

/// Uploads incident/reply photos through [UploadRepository], at most
/// [maxParallel] at a time, reporting per-photo status through a patcher.
class IncidentPhotoUploader {
  const IncidentPhotoUploader(this.repository);

  static const maxParallel = 3;

  final UploadRepository repository;

  /// Uploads every item of [photos] that still [IncidentMediaItem.needsUpload].
  /// Never throws; failures end up as [IncidentUploadStatus.failed] items.
  Future<void> upload(
    List<IncidentMediaItem> photos,
    IncidentPhotoPatcher patch,
  ) async {
    final queue = Queue<IncidentMediaItem>.of(
      photos.where((p) => p.needsUpload),
    );
    if (queue.isEmpty) return;
    final workerCount = math.min(maxParallel, queue.length);

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final item = queue.removeFirst();
        patch(
          item.id,
          (c) => c.withUpload(status: IncidentUploadStatus.uploading),
        );
        try {
          final result = await repository.uploadImage(
            item.toMediaFile(),
            // A late progress tick must not overwrite a finished status.
            onProgress: (fraction) => patch(
              item.id,
              (c) => c.isUploading
                  ? c.withUpload(
                      status: IncidentUploadStatus.uploading,
                      progress: fraction,
                    )
                  : c,
            ),
          );
          result.fold(
            (failure) => patch(
              item.id,
              (c) => c.withUpload(
                status: IncidentUploadStatus.failed,
                error: failure.message,
              ),
            ),
            (url) => patch(
              item.id,
              (c) => c.withUpload(
                status: IncidentUploadStatus.done,
                progress: 1,
                remoteUrl: url,
              ),
            ),
          );
        } on Object catch (_) {
          patch(
            item.id,
            (c) => c.withUpload(
              status: IncidentUploadStatus.failed,
              error: 'Foto gagal diunggah. Periksa koneksi lalu coba lagi.',
            ),
          );
        }
      }
    }

    await Future.wait([for (var i = 0; i < workerCount; i++) worker()]);
  }
}
