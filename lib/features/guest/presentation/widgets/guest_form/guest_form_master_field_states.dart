import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tooltip.dart';

class GuestFormDropdownSkeleton extends StatelessWidget {
  const GuestFormDropdownSkeleton({required this.shimmerController, super.key});

  final AnimationController shimmerController;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final isReducedMotion = AppMotion.isReducedMotion(context);

    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isReducedMotion ? baseColor : null,
        borderRadius: AppRadius.borderMedium,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: isReducedMotion
          ? null
          : AnimatedBuilder(
              animation: shimmerController,
              builder: (context, child) {
                return ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [baseColor, highlightColor, baseColor],
                      stops: const [0.0, 0.5, 1.0],
                      transform: _SlidingGradientTransform(
                        slidePercent: shimmerController.value,
                      ),
                    ).createShader(bounds);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: AppRadius.borderMedium,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class GuestFormMasterErrorWithRetry extends StatelessWidget {
  const GuestFormMasterErrorWithRetry({
    required this.message,
    required this.tooltipMessage,
    required this.onRetry,
    super.key,
  });

  final String message;
  final String tooltipMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typography.baseline;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space150,
        vertical: AppSpacing.space100,
      ),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: AppRadius.borderMedium,
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          AppSvgIcon(
            KawaloVectors.alertCircleFilled,
            color: colorScheme.error,
            size: 18,
          ),
          AppSpacing.hGap100,
          Expanded(
            child: Text(
              message,
              style: typeScale.bodySmall.copyWith(
                color: colorScheme.onErrorContainer,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppTooltip(
            message: tooltipMessage,
            child: AppIconButton(
              onPressed: onRetry,
              semanticLabel: tooltipMessage,
              icon: AppSvgIcon(
                KawaloVectors.reload,
                size: 16,
                color: colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2 - 1),
      0,
      0,
    );
  }
}
