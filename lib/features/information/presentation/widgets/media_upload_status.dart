import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';

/// Short Indonesian label of the upload state of [item], or `null` when there
/// is nothing to report (hosted before the form opened, or not submitting).
String? mediaUploadLabel(
  InformationFormMediaItem item, {
  required bool isSubmitting,
}) {
  switch (item.uploadStatus) {
    case MediaUploadStatus.uploading:
      return 'Mengunggah ${(item.uploadProgress * 100).round()}%';
    case MediaUploadStatus.failed:
      return item.uploadError ?? 'Gagal diunggah';
    case MediaUploadStatus.done:
      return 'Selesai diunggah';
    case MediaUploadStatus.idle:
      return isSubmitting && item.needsUpload ? 'Menunggu' : null;
  }
}

/// Scrim drawn over an image while its upload is waiting, running or failed.
/// Must be placed inside a [Stack].
class MediaUploadOverlay extends StatelessWidget {
  /// Creates a [MediaUploadOverlay].
  const MediaUploadOverlay({
    required this.item,
    required this.isSubmitting,
    super.key,
  });

  /// The attachment whose upload is reported.
  final InformationFormMediaItem item;

  /// Whether the form is submitting (queued files are then "Menunggu").
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final label = mediaUploadLabel(item, isSubmitting: isSubmitting);
    final status = item.uploadStatus;
    if (label == null || status == MediaUploadStatus.done) {
      return const SizedBox.shrink();
    }

    final theme = AppTheme.of(context);
    final failed = status == MediaUploadStatus.failed;
    final uploading = status == MediaUploadStatus.uploading;

    return Positioned.fill(
      child: Semantics(
        liveRegion: true,
        label: label,
        child: ColoredBox(
          color: (failed ? theme.colorScheme.error : theme.colorScheme.scrim)
              .withValues(alpha: 0.64),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (uploading) ...[
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      value: item.uploadProgress <= 0
                          ? null
                          : item.uploadProgress,
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                  AppSpacing.vGap50,
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space100,
                  ),
                  child: Text(
                    failed ? 'Gagal diunggah' : label,
                    textAlign: TextAlign.center,
                    style: theme.typeScale.labelSmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One-line upload status shown under a document tile.
class MediaUploadStatusLine extends StatelessWidget {
  /// Creates a [MediaUploadStatusLine].
  const MediaUploadStatusLine({
    required this.item,
    required this.isSubmitting,
    super.key,
  });

  /// The attachment whose upload is reported.
  final InformationFormMediaItem item;

  /// Whether the form is submitting (queued files are then "Menunggu").
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final label = mediaUploadLabel(item, isSubmitting: isSubmitting);
    if (label == null) return const SizedBox.shrink();

    final theme = AppTheme.of(context);
    final failed = item.uploadStatus == MediaUploadStatus.failed;
    final uploading = item.uploadStatus == MediaUploadStatus.uploading;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space100),
      child: Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (uploading) ...[
              LinearProgressIndicator(
                value: item.uploadProgress <= 0 ? null : item.uploadProgress,
              ),
              AppSpacing.vGap50,
            ],
            Text(
              label,
              style: theme.typeScale.bodySmall.copyWith(
                color: failed
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
