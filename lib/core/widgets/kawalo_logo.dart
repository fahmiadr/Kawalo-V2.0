import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';

/// Reusable brand logo wordmark widget for Kawalo Mobile.
///
/// Displays the "KAWALO" logo where "KA" and "ALO" use [textColor] (default:
/// `colorScheme.onSurface`) and "W" uses [primaryColor] (default:
/// `colorScheme.primary`).
///
/// Features built-in [FittedBox] scaling protection and accessible semantics,
/// preventing overflow during 200% dynamic text scaling while ensuring screen
/// readers announce the brand name as a unified entity.
class KawaloLogoText extends StatelessWidget {
  const KawaloLogoText({
    super.key,
    this.fontSize = 28.0,
    this.primaryColor,
    this.textColor,
    this.letterSpacing,
    this.fit,
    this.alignment = Alignment.centerLeft,
    this.semanticLabel = 'Kawalo',
    this.height = 1.0,
    this.textScaler,
  });

  /// The font size of the logo text in dp (default: 28.0).
  final double fontSize;

  /// Custom color for the "W" character (default: `colorScheme.primary`).
  final Color? primaryColor;

  /// Custom color for "KA" and "ALO" characters (default:
  /// `colorScheme.onSurface`).
  final Color? textColor;

  /// Custom tracking / letter spacing in dp.
  /// If null, calculates proportional tracking: `-fontSize * 0.05`.
  final double? letterSpacing;

  /// Optional scaling fit to inscribe the logo into allocated space.
  /// When null, renders at exact natural [fontSize] without vertical shrinkage.
  final BoxFit? fit;

  /// The alignment of the logo within its parent bounds when [fit] is provided.
  final AlignmentGeometry alignment;

  /// Accessible label for screen readers (default: "Kawalo").
  final String? semanticLabel;

  /// Optional line height multiplier (default: 1.0 for tight graphic
  /// bounding box).
  final double? height;

  /// Optional text scaler to control accessibility font magnification.
  /// Set to [TextScaler.noScaling] in fixed app bars to protect against
  /// layout collision.
  final TextScaler? textScaler;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveTextColor = textColor ?? colorScheme.onSurface;
    final effectivePrimaryColor = primaryColor ?? colorScheme.primary;
    final effectiveLetterSpacing = letterSpacing ?? (-fontSize * 0.05);

    final baseStyle = theme.typography.emphasized.displayLarge.copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: effectiveLetterSpacing,
      height: height,
      leadingDistribution: TextLeadingDistribution.even,
    );

    final darkTextStyle = baseStyle.copyWith(color: effectiveTextColor);

    final greenTextStyle = baseStyle.copyWith(color: effectivePrimaryColor);

    Widget textWidget = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'KA', style: darkTextStyle),
          TextSpan(text: 'W', style: greenTextStyle),
          TextSpan(text: 'ALO', style: darkTextStyle),
        ],
      ),
      textScaler: textScaler,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (fit != null) {
      textWidget = FittedBox(
        fit: fit!,
        alignment: alignment,
        child: textWidget,
      );
    }

    return Semantics(
      header: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: textWidget,
    );
  }
}
