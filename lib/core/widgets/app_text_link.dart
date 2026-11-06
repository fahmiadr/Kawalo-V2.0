import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';

/// Widget header baris teks dengan tombol aksi tautan bergaris bawah
/// di sisi kanan menggunakan [AppButton] berpenampilan teks sesuai Figma.
class AppTextLink extends StatelessWidget {
  /// Membuat instance [AppTextLink].
  const AppTextLink({
    required this.title,
    this.linkText,
    super.key,
    this.onPressed,
    this.titleStyle,
    this.linkStyle,
    this.underlineColor,
    this.semanticLabel,
  });

  /// Teks judul di sisi kiri baris.
  final String title;

  /// Teks tautan aksi di sisi kanan baris (opsional).
  ///
  /// Jika null atau kosong, hanya teks judul yang di-render tanpa tombol
  /// tautan aksi.
  final String? linkText;

  /// Callback saat tautan ditekan.
  final VoidCallback? onPressed;

  /// Override gaya teks judul (opsional).
  final TextStyle? titleStyle;

  /// Override gaya teks tautan (opsional).
  final TextStyle? linkStyle;

  /// Override warna garis bawah tautan (opsional).
  final Color? underlineColor;

  /// Label semantik untuk aksesibilitas pembaca layar (opsional).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final emphasizedTypeScale = theme.typography.emphasized;

    final isLinkEnabled = onPressed != null;

    final effectiveTitleStyle = titleStyle ??
        emphasizedTypeScale.titleLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        );

    final linkColor = linkStyle?.color ?? colorScheme.onSurface;

    final effectiveLinkColor = isLinkEnabled
        ? linkColor
        : linkColor.withValues(alpha: AppStateLayer.disabledOpacity);

    final effectiveLinkStyle = (linkStyle ??
            emphasizedTypeScale.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ))
        .copyWith(color: effectiveLinkColor);

    final effectiveUnderlineColor = underlineColor ??
        (isLinkEnabled
            ? colorScheme.primary
            : colorScheme.primary
                .withValues(alpha: AppStateLayer.disabledOpacity));

    final hasLink = linkText != null && linkText!.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ── Judul di Sisi Kiri ─────────────────────────────────────────────
        Expanded(
          child: Text(
            title,
            style: effectiveTitleStyle,
          ),
        ),

        if (hasLink) ...[
          AppSpacing.hGap200,

          // ── Tombol Tautan Aksi (AppButton + Underline Decorator) ──────────
          AppButton(
            style: AppButtonColor.text,
            enabled: isLinkEnabled,
            onPressed: onPressed,
            shape: AppButtonShape.square,
            semanticLabel: semanticLabel ?? '$linkText $title',
            decoration: AppButtonDecoration(
              padding: AppSpacing.paddingAll50,
              foregroundColor:
                  WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.disabled)) {
                  return effectiveLinkColor;
                }
                return linkColor;
              }),
            ),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    linkText!,
                    textAlign: TextAlign.right,
                    style: effectiveLinkStyle,
                  ),
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: effectiveUnderlineColor,
                      borderRadius: AppRadius.borderFull,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
