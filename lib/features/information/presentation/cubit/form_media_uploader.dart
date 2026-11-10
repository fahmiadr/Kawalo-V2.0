import 'dart:math' as math;

import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';

/// Uploads one item and reports progress as a fraction.
typedef MediaUploadCall =
    Future<Either<Failure, String>> Function(
      InformationFormMediaItem item,
      UploadProgress onProgress,
    );

/// Applies the update function to the form item with the given id, wherever
/// it lives in state.
typedef MediaPatch =
    void Function(
      String id,
      InformationFormMediaItem Function(InformationFormMediaItem) update,
    );

/// Shared upload step of the guest and information forms: sends every local
/// file that is not hosted yet, a few at a time, and records the per-file
/// status on the form item.
abstract final class FormMediaUploader {
  /// Upper bound of simultaneous uploads.
  static const int maxParallel = 3;

  /// Minimum progress change worth emitting a new form state for.
  static const double _progressStep = 0.05;

  /// Uploads the items that [InformationFormMediaItem.needsUpload] and returns
  /// the number of files that failed (0 means everything is hosted).
  ///
  /// Hosted files are skipped, so calling this again after a failure retries
  /// only the files that failed.
  static Future<int> uploadPending(
    List<InformationFormMediaItem> items, {
    required MediaUploadCall upload,
    required MediaPatch patch,
    bool Function()? isCancelled,
  }) async {
    final pending = items.where((i) => i.needsUpload).toList();
    var cursor = 0;
    var failed = 0;

    Future<void> worker() async {
      while (cursor < pending.length) {
        final item = pending[cursor++];
        patch(
          item.id,
          (i) => i.copyWith(
            uploadStatus: MediaUploadStatus.uploading,
            uploadProgress: 0,
            uploadError: () => null,
          ),
        );

        var finished = false;
        var lastReported = 0.0;
        final result = await upload(item, (fraction) {
          final clamped = fraction.clamp(0.0, 1.0);
          if (finished || clamped - lastReported < _progressStep) return;
          lastReported = clamped;
          patch(item.id, (i) => i.copyWith(uploadProgress: clamped));
        });
        finished = true;
        if (isCancelled?.call() ?? false) return;

        result.fold(
          (failure) {
            failed++;
            patch(
              item.id,
              (i) => i.copyWith(
                uploadStatus: MediaUploadStatus.failed,
                uploadError: () => failure.message.isEmpty
                    ? 'Gagal mengunggah berkas.'
                    : failure.message,
              ),
            );
          },
          (url) {
            patch(
              item.id,
              (i) => i.copyWith(
                uploadStatus: MediaUploadStatus.done,
                uploadProgress: 1,
                remoteUrl: url,
                uploadError: () => null,
              ),
            );
          },
        );
      }
    }

    await Future.wait([
      for (var n = 0; n < math.min(maxParallel, pending.length); n++) worker(),
    ]);
    return failed;
  }

  /// Message shown when [failed] files could not be uploaded.
  static String failureMessage(int failed) {
    final subject = failed == 1 ? '1 berkas' : '$failed berkas';
    return '$subject gagal diunggah. Periksa koneksi lalu coba kirim lagi.';
  }
}
