import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_shape.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

/// Uniform fallback placeholder widget for missing or loading image assets
/// across the application (e.g., Logo, Illustration, Avatar, Thumbnail).
///
/// Fully compliant with Material 3 Design System, AppShape tokens,
/// Color Roles, and WCAG 2.1/2.2 AA Accessibility Standards.
///
/// Supports custom [icon] widget or optional [iconPath] for SVG vector / image asset.
class AppImagePlaceholder extends StatelessWidget {
  const AppImagePlaceholder({
    this.label = '',
    super.key,
    this.icon,
    this.iconPath,
    this.iconSize = 36.0,
    this.width,
    this.height,
    this.shape,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
    this.semanticLabel,
  });

  final String label;
  final Widget? icon;
  final String? iconPath;
  final double iconSize;
  final double? width;
  final double? height;
  final OutlinedBorder? shape;
  final BorderRadiusGeometry? borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;

    // Standard M3 Color Role pairing:
    // Surface Container Highest -> On Surface Variant
    final effectiveBgColor =
        backgroundColor ?? colorScheme.surfaceContainerHighest;
    final effectiveContentColor =
        foregroundColor ?? colorScheme.onSurfaceVariant;

    final effectiveShape = shape ??
        (borderRadius != null
            ? RoundedRectangleBorder(borderRadius: borderRadius!)
            : AppShape.small);

    final effectiveIconPath = (iconPath != null && iconPath!.isNotEmpty)
        ? iconPath!
        : KawaloVectors.imageNotFound01;

    final visualWidget = icon ??
        AppSvgIcon(
          effectiveIconPath,
          size: iconSize,
          color: effectiveContentColor,
        );

    final hasLabel = label.trim().isNotEmpty;
    final effectiveSemanticLabel =
        semanticLabel ?? (hasLabel ? 'Gambar: $label' : 'Placeholder gambar');

    return Semantics(
      label: effectiveSemanticLabel,
      excludeSemantics: true,
      child: Container(
        width: width,
        height: height,
        padding: AppSpacing.paddingAllSm,
        decoration: ShapeDecoration(
          color: effectiveBgColor,
          shape: effectiveShape,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            visualWidget,
            if (hasLabel) ...[
              AppSpacing.gapXs,
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typeScale.labelSmall.copyWith(
                    color: effectiveContentColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.50,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
