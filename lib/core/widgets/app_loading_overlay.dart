import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';

/// Full-screen modal scrim overlay featuring an expressive loading indicator.
///
/// Designed to block user interactions during asynchronous operations
/// (such as authentication, group switching, data syncing, or account
/// verification) while maintaining WCAG AA contrast and assistive technology
/// announcements.
///
/// By default, it renders an [AppLoadingIndicatorSize.medium] indicator
/// with [AppLoadingIndicatorVariant.contained] and an elevation of 2 over a
/// standard Material 3 semi-transparent scrim. When an optional [message] is
/// provided, the indicator and message are presented together in a cohesive
/// Material 3 surface container card with high contrast.
///
/// ### Usage Patterns:
///
/// 1. **Direct Stack Overlay (Default)**:
/// ```dart
/// Stack(
///   children: [
///     Scaffold(...),
///     if (isLoading)
///       const AppLoadingOverlay(
///         semanticLabel: 'Memverifikasi akun',
///       ),
///   ],
/// )
/// ```
///
/// 2. **Child Wrapper**:
/// ```dart
/// AppLoadingOverlay(
///   isLoading: isLoading,
///   semanticLabel: 'Memverifikasi akun',
///   child: Scaffold(...),
/// )
/// ```
class AppLoadingOverlay extends StatelessWidget {
  /// Creates an [AppLoadingOverlay].
  const AppLoadingOverlay({
    super.key,
    this.isLoading = true,
    this.semanticLabel,
    this.message,
    this.size = AppLoadingIndicatorSize.medium,
    this.indicatorVariant = AppLoadingIndicatorVariant.contained,
    this.elevation = 2,
    this.scrimColor,
    this.isPositioned = true,
    this.child,
  });

  /// Controls overlay visibility when [child] is provided or when
  /// conditionally displayed.
  final bool isLoading;

  /// Accessibility label announced by screen readers.
  final String? semanticLabel;

  /// Optional text message displayed beneath the loading indicator.
  final String? message;

  /// Size of the expressive loading indicator.
  /// Defaults to [AppLoadingIndicatorSize.medium] (48x48dp container, 38dp
  /// active shape).
  final AppLoadingIndicatorSize size;

  /// Visual variant of the loading indicator.
  /// Defaults to [AppLoadingIndicatorVariant.contained].
  final AppLoadingIndicatorVariant indicatorVariant;

  /// Elevation shadow for the contained indicator shell or modal card.
  final double elevation;

  /// Custom background scrim color.
  /// Defaults to [ColorScheme.scrim] with 32% opacity (0.32).
  final Color? scrimColor;

  /// Whether to wrap the overlay in a [Positioned.fill] for [Stack] placement.
  /// Set to `false` when placing inside dialogs or custom layout boundaries.
  final bool isPositioned;

  /// Optional widget tree to wrap with this loading overlay.
  final Widget? child;

  Widget _buildOverlayContent(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final emphasizedTypeScale = theme.typography.emphasized;

    final effectiveScrimColor =
        scrimColor ?? colorScheme.scrim.withValues(alpha: 0.32);

    final hasMessage = message != null && message!.isNotEmpty;
    final hasSemanticLabel =
        semanticLabel != null && semanticLabel!.isNotEmpty;

    final Widget content;
    if (hasMessage) {
      content = Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space300,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 140,
            maxWidth: 280,
          ),
          child: Material(
            color: colorScheme.surfaceContainerHigh,
            elevation: elevation,
            borderRadius: AppRadius.borderExtraLarge,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space300,
                vertical: AppSpacing.space300,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLoadingIndicator(
                    size: size,
                    elevation: 0,
                  ),
                  AppSpacing.vGap200,
                  Text(
                    message!,
                    style: emphasizedTypeScale.titleSmall.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      content = AppLoadingIndicator(
        variant: indicatorVariant,
        size: size,
        elevation: elevation,
        semanticLabel: semanticLabel,
      );
    }

    final effectiveContent = hasMessage
        ? Semantics(
            label: hasSemanticLabel ? semanticLabel : null,
            container: true,
            child: ExcludeSemantics(
              excluding: hasSemanticLabel,
              child: content,
            ),
          )
        : content;

    return AbsorbPointer(
      child: ColoredBox(
        color: effectiveScrimColor,
        child: Center(
          child: SingleChildScrollView(
            child: effectiveContent,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // When wrapping a child widget
    if (child != null) {
      return Stack(
        fit: StackFit.passthrough,
        children: [
          child!,
          if (isLoading)
            Positioned.fill(
              child: _buildOverlayContent(context),
            ),
        ],
      );
    }

    // Direct overlay usage (e.g. within an existing Stack)
    if (!isLoading) {
      return const SizedBox.shrink();
    }

    if (isPositioned) {
      return Positioned.fill(
        child: _buildOverlayContent(context),
      );
    }

    return _buildOverlayContent(context);
  }
}
