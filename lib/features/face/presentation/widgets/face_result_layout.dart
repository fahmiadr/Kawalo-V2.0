import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

/// Colour of the result badge. Green is the brand primary; red is the theme
/// error role.
enum FaceResultTone { success, error, neutral }

class FaceResultAction {
  const FaceResultAction(
    this.label,
    this.onPressed, {
    this.style = AppButtonColor.filled,
  });

  final String label;
  final VoidCallback onPressed;
  final AppButtonColor style;
}

/// Full-screen outcome of the face and attendance flows (`fx-res` artboards):
/// a round badge, a title, a message, optional content and a button dock.
class FaceResultLayout extends StatelessWidget {
  const FaceResultLayout({
    required this.tone,
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
    super.key,
    this.content = const [],
    this.onClose,
  });

  final FaceResultTone tone;
  final String icon;
  final String title;
  final String message;
  final List<Widget> content;
  final List<FaceResultAction> actions;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorSchemeOf(context);
    final typeScale = AppTheme.typeScaleOf(context);
    final (background, foreground) = switch (tone) {
      FaceResultTone.success => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      FaceResultTone.error => (colors.errorContainer, colors.onErrorContainer),
      FaceResultTone.neutral => (
        colors.surfaceContainerHigh,
        colors.onSurfaceVariant,
      ),
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (onClose != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.space100),
                  child: AppIconButton(
                    semanticLabel: 'Tutup',
                    onPressed: onClose,
                    icon: const AppSvgIcon(KawaloVectors.cancel01),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space300,
                  AppSpacing.space300,
                  AppSpacing.space300,
                  AppSpacing.space200,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: background,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: AppSvgIcon(icon, size: 56, color: foreground),
                      ),
                    ),
                    AppSpacing.vGap300,
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: typeScale.headlineSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    AppSpacing.vGap100,
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: typeScale.bodyMedium.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (content.isNotEmpty) ...[AppSpacing.vGap300, ...content],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space200,
                AppSpacing.space150,
                AppSpacing.space200,
                AppSpacing.space300,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, action) in actions.indexed) ...[
                    if (i > 0) AppSpacing.vGap100,
                    AppButton(
                      style: action.style,
                      size: AppButtonSize.md,
                      onPressed: action.onPressed,
                      child: Text(action.label),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded `fx-card` panel holding [FaceInfoRow]s or text.
class FaceInfoCard extends StatelessWidget {
  const FaceInfoCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorSchemeOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space200,
          vertical: AppSpacing.space50,
        ),
        child: Column(
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) Divider(height: 1, color: colors.outlineVariant),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

/// Label above a bold value, with a leading icon (`fx-kv`).
class FaceInfoRow extends StatelessWidget {
  const FaceInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorSchemeOf(context);
    final typeScale = AppTheme.typeScaleOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space150),
      child: Row(
        children: [
          AppSvgIcon(icon, size: 24, color: colors.primary),
          AppSpacing.hGap150,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: typeScale.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: typeScale.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
