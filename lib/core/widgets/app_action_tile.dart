import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

/// Komponen baris aksi interaktif berbasis Material 3 Expressive
/// untuk digunakan pada Contextual Action Sheet, Bottom Sheet Menu,
/// maupun daftar perintah langsung lainnya.
class AppActionTile extends StatelessWidget {
  /// Membuat instance [AppActionTile].
  const AppActionTile({
    required this.title,
    required this.onTap,
    super.key,
    this.vectorIcon,
    this.leading,
    this.subtitle,
    this.isDestructive = false,
    this.closeOnTap = true,
    this.trailing,
    this.semanticLabel,
    this.shape = AppButtonShape.square,
    this.contentPadding,
  });

  /// Label teks utama aksi (misal: "Buka foto", "Jadikan foto utama").
  final String title;

  /// Keterangan atau subjudul pendukung aksi (opsional).
  final String? subtitle;

  /// Aset SVG vektor untuk ikon awalan (misal: `KawaloVectors.view`).
  final String? vectorIcon;

  /// Widget awalan kustom sebagai alternatif jika bukan [AppSvgIcon].
  final Widget? leading;

  /// Callback yang dipicu saat baris aksi diketuk.
  final VoidCallback onTap;

  /// Menandakan apakah aksi ini destruktif (misal: "Hapus foto ini").
  /// Jika `true`, teks dan ikon secara otomatis diwarnai `colorScheme.error`.
  final bool isDestructive;

  /// Menandakan apakah modal/sheet saat ini harus ditutup otomatis
  /// via [Navigator.pop] sesaat sebelum [onTap] dieksekusi (default: `true`).
  final bool closeOnTap;

  /// Widget akhiran opsional di sisi kanan baris (misal: shortcut, badge).
  final Widget? trailing;

  /// Label aksesibilitas untuk screen reader (opsional).
  final String? semanticLabel;

  /// Bentuk ripple/state layer tombol (default: [AppButtonShape.square]).
  final AppButtonShape shape;

  /// Padding horizontal kustom (opsional).
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;

    final effectiveColor = isDestructive
        ? colorScheme.error
        : colorScheme.onSurface;

    Widget? leadingWidget;
    if (leading != null) {
      leadingWidget = leading;
    } else if (vectorIcon != null) {
      leadingWidget = AppSvgIcon(vectorIcon!, size: 20, color: effectiveColor);
    }

    final titleWidget = Text(
      title,
      style: typeScale.bodyLarge,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    Widget textColumn;
    if (subtitle != null) {
      textColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          titleWidget,
          AppSpacing.vGap25,
          Text(
            subtitle!,
            style: typeScale.bodySmall.copyWith(
              color: isDestructive
                  ? colorScheme.error.withValues(alpha: 0.8)
                  : colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    } else {
      textColumn = titleWidget;
    }

    return AppButton(
      style: AppButtonColor.text,
      shape: shape,
      size: AppButtonSize.custom(
        height: AppStateLayer.minTouchTarget,
        hPadding: AppSpacing.space150,
      ),
      semanticLabel:
          semanticLabel ?? (subtitle != null ? '$title, $subtitle' : title),
      decoration: AppButtonDecoration(
        foregroundColor: WidgetStatePropertyAll<Color?>(effectiveColor),
      ),
      onPressed: () {
        if (closeOnTap) {
          Navigator.of(context).pop();
        }
        onTap();
      },
      child: Row(
        children: [
          if (leadingWidget != null) ...[leadingWidget, AppSpacing.hGap150],
          Expanded(child: textColumn),
          if (trailing != null) ...[AppSpacing.hGap150, trailing!],
        ],
      ),
    );
  }
}
