import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';

/// Komponen baris seleksi interaktif berbasis Material 3 Expressive
/// untuk digunakan pada Filter Modal, Radio Picker, Checkbox List,
/// atau formulir pemilihan nilai tunggal/ganda.
class AppSelectionTile extends StatelessWidget {
  /// Membuat instance [AppSelectionTile].
  const AppSelectionTile({
    required this.title,
    required this.onTap,
    super.key,
    this.subtitle,
    this.subtitleWidget,
    this.leading,
    this.trailing,
    this.selected = false,
    this.semanticLabel,
    this.shape = AppButtonShape.square,
    this.hPadding = AppSpacing.space50,
    this.minHeight = AppStateLayer.minTouchTarget,
  });

  /// Label teks utama opsi (misal: "Hari ini", "Pekan ini", nama personil).
  final String title;

  /// Subjudul deskripsi opsi dalam teks sederhana (opsional).
  final String? subtitle;

  /// Subjudul alternatif berupa widget kustom
  /// (misal: teks tanggal terformat berwarna `colorScheme.primary`).
  final Widget? subtitleWidget;

  /// Widget awalan di sisi kiri (misal: Avatar profil personil atau ikon).
  final Widget? leading;

  /// Widget kontrol penanda seleksi di sisi kanan
  /// (misal: `AppRadio` atau `AppCheckbox`).
  final Widget? trailing;

  /// Menandakan apakah item ini sedang dalam status terpilih (opsional).
  final bool selected;

  /// Callback saat baris seleksi diketuk.
  final VoidCallback onTap;

  /// Label semantik untuk pembaca layar (opsional).
  final String? semanticLabel;

  /// Bentuk ripple/state layer tombol (default: [AppButtonShape.square]).
  final AppButtonShape shape;

  /// Padding horizontal konten (default: [AppSpacing.space50] = 4dp).
  final double hPadding;

  /// Batas tinggi minimal target sentuh
  /// (default: [AppStateLayer.minTouchTarget] = 48dp).
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;

    Widget? effectiveSubtitle;
    if (subtitleWidget != null) {
      effectiveSubtitle = subtitleWidget;
    } else if (subtitle != null) {
      effectiveSubtitle = Text(
        subtitle!,
        style: typeScale.bodySmall.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return AppButton(
      style: AppButtonColor.text,
      shape: shape,
      size: AppButtonSize.custom(
        height: minHeight,
        hPadding: hPadding,
      ),
      semanticLabel: semanticLabel ?? 'Pilih $title',
      decoration: AppButtonDecoration(
        foregroundColor: WidgetStatePropertyAll<Color?>(
          colorScheme.onSurface,
        ),
      ),
      onPressed: onTap,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            AppSpacing.hGapSm,
          ],
          Expanded(
            child: effectiveSubtitle == null
                ? Text(
                    title,
                    style: typeScale.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: typeScale.bodyLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppSpacing.vGap25,
                      effectiveSubtitle,
                    ],
                  ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
