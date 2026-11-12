import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/face_camera.dart';

/// Front-camera screen with the face oval (`fx-cam` artboards): preview, a
/// hint pill under the oval and a bottom panel.
class FaceCameraView extends StatelessWidget {
  const FaceCameraView({
    required this.title,
    required this.hint,
    required this.hintOk,
    required this.heading,
    required this.message,
    required this.cancelLabel,
    super.key,
    this.onCancel,
    this.extraActionLabel,
    this.onExtraAction,
    this.camera,
    this.progress,
    this.busy = false,
  });

  final FaceCamera? camera;
  final String title;
  final String hint;

  /// Green oval and check icon when the face passes the gate.
  final bool hintOk;
  final String heading;
  final String message;
  final String cancelLabel;

  /// Null while a request is in flight: leaving would not undo it.
  final VoidCallback? onCancel;

  /// Optional second choice stacked above the cancel button.
  final String? extraActionLabel;
  final VoidCallback? onExtraAction;

  /// `(done, total)` segments, e.g. photos taken.
  final (int, int)? progress;

  /// Shows a spinner in the panel (sending to the server).
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorSchemeOf(context);
    final typeScale = AppTheme.typeScaleOf(context);
    final emphasized = AppTheme.emphasizedTypeScaleOf(context);
    final ovalColor = hintOk ? colors.primary : Colors.white;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (camera != null) camera!.buildPreview(context),
                IgnorePointer(
                  child: CustomPaint(painter: _OvalMask(ovalColor)),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.space100),
                    child: Row(
                      children: [
                        if (onCancel == null)
                          const SizedBox(width: 48)
                        else
                          AppIconButton(
                            semanticLabel: cancelLabel,
                            onPressed: onCancel,
                            decoration: M3EIconButtonDecoration(
                              backgroundColor: WidgetStatePropertyAll(
                                colors.scrim.withValues(alpha: 0.6),
                              ),
                            ),
                            icon: const AppSvgIcon(
                              KawaloVectors.cancel01,
                              color: Colors.white,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: emphasized.titleMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, 0.62),
                  child: Semantics(
                    liveRegion: true,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space200,
                        vertical: AppSpacing.space100,
                      ),
                      decoration: BoxDecoration(
                        color: hintOk
                            ? colors.primaryContainer
                            : colors.scrim.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hintOk) ...[
                            AppSvgIcon(
                              KawaloVectors.check,
                              size: 18,
                              color: colors.onPrimaryContainer,
                            ),
                            AppSpacing.hGap50,
                          ],
                          Flexible(
                            child: Text(
                              hint,
                              textAlign: TextAlign.center,
                              style: typeScale.labelLarge.copyWith(
                                color: hintOk
                                    ? colors.onPrimaryContainer
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.space200,
              AppSpacing.space300,
              AppSpacing.space200,
              AppSpacing.space300 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.extraLarge),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  heading,
                  textAlign: TextAlign.center,
                  style: emphasized.titleLarge,
                ),
                AppSpacing.vGap50,
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: typeScale.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (busy) ...[
                  AppSpacing.vGap200,
                  const Center(
                    child: AppLoadingIndicator(
                      size: AppLoadingIndicatorSize.small,
                    ),
                  ),
                ],
                if (progress case (final done, final total)) ...[
                  AppSpacing.vGap200,
                  Row(
                    children: [
                      for (var i = 0; i < total; i++) ...[
                        if (i > 0) AppSpacing.hGap50,
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: i < done
                                  ? colors.primary
                                  : colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                if (extraActionLabel != null && onExtraAction != null) ...[
                  AppSpacing.vGap200,
                  AppButton(
                    style: AppButtonColor.tonal,
                    size: AppButtonSize.md,
                    onPressed: onExtraAction,
                    child: Text(extraActionLabel!),
                  ),
                ],
                if (onCancel case final cancel?) ...[
                  if (extraActionLabel != null && onExtraAction != null)
                    AppSpacing.vGap100
                  else
                    AppSpacing.vGap200,
                  AppButton(
                    style: AppButtonColor.tonal,
                    size: AppButtonSize.md,
                    onPressed: cancel,
                    child: Text(cancelLabel),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Darkens everything outside a centred portrait oval.
class _OvalMask extends CustomPainter {
  const _OvalMask(this.borderColor);

  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width * 0.68;
    final oval = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.44),
      width: width,
      height: width * 1.3,
    );
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(oval);
    canvas
      ..drawPath(mask, Paint()..color = Colors.black.withValues(alpha: 0.55))
      ..drawOval(
        oval,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
  }

  @override
  bool shouldRepaint(_OvalMask oldDelegate) =>
      oldDelegate.borderColor != borderColor;
}
