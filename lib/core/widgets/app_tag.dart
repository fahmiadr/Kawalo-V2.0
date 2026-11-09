import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';

/// Semantic color variants for [AppTag] mapped to Material 3 container roles.
enum AppTagVariant {
  /// Primary container and on-primary-container role pairing.
  primary,

  /// Secondary container and on-secondary-container role pairing.
  secondary,

  /// Tertiary container and on-tertiary-container role pairing.
  tertiary,

  /// Error container and on-error-container role pairing.
  error,

  /// Surface container highest and on-surface-variant role pairing.
  neutral,
}

/// Visual size variants for [AppTag].
enum AppTagSize {
  /// Compact size suitable for dense list items, card metadata, and timestamps.
  small,

  /// Standard medium size for general tag/badge indicators.
  medium,

  /// Prominent size for highlighted headers or standalone callouts.
  large,
}

/// A pure static, read-only metadata tag/badge component adhering strictly
/// to Material Design 3 Expressive tokens and container roles.
///
/// Designed to be embedded safely within interactive containers (such as
/// `AppCard`) without causing nested interactive control conflicts, ripple
/// collisions, or assistive technology confusion.
class AppTag extends StatelessWidget {
  /// Creates a pure static [AppTag].
  const AppTag({
    required this.label,
    super.key,
    this.variant = AppTagVariant.primary,
    this.size = AppTagSize.medium,
    this.isOutlined = false,
    this.leading,
    this.trailing,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderRadius,
    this.semanticLabel,
  });

  /// The text content displayed inside the tag.
  final String label;

  /// The semantic color variant defining container and content tokens.
  final AppTagVariant variant;

  /// The dimension and typography scale of the tag.
  final AppTagSize size;

  /// Whether the tag is rendered in outlined style rather than filled.
  final bool isOutlined;

  /// Optional leading widget (e.g. status dot indicator or icon).
  final Widget? leading;

  /// Optional trailing widget (e.g. status mark or counter).
  final Widget? trailing;

  /// Optional background color override. If null, resolved from [variant].
  final Color? backgroundColor;

  /// Optional text/content color override. If null, resolved from [variant].
  final Color? textColor;

  /// Optional border color override for outlined style or custom borders.
  final Color? borderColor;

  /// Optional border radius override. Defaults to [AppRadius.borderFull].
  final BorderRadiusGeometry? borderRadius;

  /// Optional accessible label announced by screen readers.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;

    // Resolve semantic colors based on variant
    final (resolvedBg, resolvedFg, resolvedBorder) = _resolveColors(
      colorScheme,
    );

    final effectiveBg =
        backgroundColor ?? (isOutlined ? Colors.transparent : resolvedBg);
    final effectiveFg = textColor ?? resolvedFg;
    final effectiveBorderColor = borderColor ?? resolvedBorder;

    // Resolve size-dependent metrics
    final (padding, textStyle, gap, iconThemeSize) = _resolveMetrics(
      typeScale,
      effectiveFg,
    );

    final effectiveBorderRadius = borderRadius ?? AppRadius.borderFull;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[
          IconTheme(
            data: IconThemeData(color: effectiveFg, size: iconThemeSize),
            child: leading!,
          ),
          SizedBox(width: gap),
        ],
        Text(
          label,
          style: textStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (trailing != null) ...[
          SizedBox(width: gap),
          IconTheme(
            data: IconThemeData(color: effectiveFg, size: iconThemeSize),
            child: trailing!,
          ),
        ],
      ],
    );

    return Semantics(
      container: true,
      label: semanticLabel ?? label,
      excludeSemantics: semanticLabel != null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: effectiveBorderRadius,
          border: isOutlined || borderColor != null
              ? Border.all(color: effectiveBorderColor)
              : null,
        ),
        child: Padding(padding: padding, child: content),
      ),
    );
  }

  (Color bg, Color fg, Color border) _resolveColors(
    M3EColorScheme colorScheme,
  ) {
    switch (variant) {
      case AppTagVariant.primary:
        return (
          colorScheme.primaryContainer,
          colorScheme.onPrimaryContainer,
          colorScheme.primary,
        );
      case AppTagVariant.secondary:
        return (
          colorScheme.secondaryContainer,
          colorScheme.onSecondaryContainer,
          colorScheme.secondary,
        );
      case AppTagVariant.tertiary:
        return (
          colorScheme.tertiaryContainer,
          colorScheme.onTertiaryContainer,
          colorScheme.tertiary,
        );
      case AppTagVariant.error:
        return (
          colorScheme.errorContainer,
          colorScheme.onErrorContainer,
          colorScheme.error,
        );
      case AppTagVariant.neutral:
        return (
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurfaceVariant,
          colorScheme.outlineVariant,
        );
    }
  }

  (EdgeInsets padding, TextStyle textStyle, double gap, double iconSize)
  _resolveMetrics(M3ETypeScale typeScale, Color contentColor) {
    switch (size) {
      case AppTagSize.small:
        return (
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.space100,
            vertical: AppSpacing.space25,
          ),
          typeScale.labelSmall.copyWith(
            color: contentColor,
            fontWeight: FontWeight.w500,
          ),
          AppSpacing.space50,
          12.0,
        );
      case AppTagSize.medium:
        return (
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.space150,
            vertical: AppSpacing.space50,
          ),
          typeScale.labelMedium.copyWith(
            color: contentColor,
            fontWeight: FontWeight.w500,
          ),
          AppSpacing.space75,
          16.0,
        );
      case AppTagSize.large:
        return (
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.space200,
            vertical: AppSpacing.space75,
          ),
          typeScale.labelLarge.copyWith(
            color: contentColor,
            fontWeight: FontWeight.w500,
          ),
          AppSpacing.space100,
          18.0,
        );
    }
  }
}
