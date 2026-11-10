import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/features/incident/presentation/models/incident_media_item.dart';

/// Scrim over a photo showing its upload state: waiting, progress or failed
/// with a retry action. Renders nothing for uploaded photos (and for pending
/// ones unless [showWaiting] is set).
class IncidentPhotoUploadOverlay extends StatelessWidget {
  const IncidentPhotoUploadOverlay({
    required this.item,
    this.onRetry,
    this.showWaiting = false,
    this.compact = false,
    super.key,
  });

  final IncidentMediaItem item;

  /// Retries a failed upload; null disables the retry action.
  final VoidCallback? onRetry;

  /// Whether a pending photo is shown as "Menunggu" (an upload is under way).
  final bool showWaiting;

  /// Small variant for thumbnails without room for a button or message.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final status = item.uploadStatus;
    if (status == IncidentUploadStatus.done ||
        (status == IncidentUploadStatus.pending && !showWaiting)) {
      return const SizedBox.shrink();
    }

    final theme = AppTheme.of(context);
    final labelStyle = theme.typeScale.labelSmall.copyWith(color: Colors.white);

    final Widget content;
    switch (status) {
      case IncidentUploadStatus.uploading:
        final percent = (item.uploadProgress.clamp(0, 1) * 100).round();
        content = Semantics(
          liveRegion: true,
          label: 'Mengunggah foto $percent persen',
          child: ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: AppLoadingIndicator(
                    size: AppLoadingIndicatorSize.small,
                  ),
                ),
                AppSpacing.vGap25,
                Text('$percent%', style: labelStyle),
              ],
            ),
          ),
        );
      case IncidentUploadStatus.failed:
        content = compact
            ? Semantics(
                button: true,
                label: 'Unggahan foto gagal. Ketuk untuk mencoba lagi',
                child: ExcludeSemantics(
                  child: Text(
                    'Gagal\nCoba lagi',
                    style: labelStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fixed width: FittedBox gives unbounded constraints and the
                  // message would otherwise never wrap.
                  SizedBox(
                    width: 140,
                    child: Text(
                      item.uploadError ?? 'Foto gagal diunggah.',
                      style: labelStyle,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppSpacing.vGap50,
                  AppButton(
                    size: AppButtonSize.xs,
                    onPressed: onRetry,
                    semanticLabel: 'Coba unggah ulang foto',
                    child: const Text('Coba lagi'),
                  ),
                ],
              );
      case IncidentUploadStatus.pending:
        content = Text('Menunggu...', style: labelStyle);
      case IncidentUploadStatus.done:
        content = const SizedBox.shrink();
    }

    final scrim = ColoredBox(
      color: theme.colorScheme.scrim.withValues(alpha: 0.6),
      child: Center(
        child: FittedBox(fit: BoxFit.scaleDown, child: content),
      ),
    );

    if (compact && status == IncidentUploadStatus.failed && onRetry != null) {
      return GestureDetector(onTap: onRetry, child: scrim);
    }
    return scrim;
  }
}
