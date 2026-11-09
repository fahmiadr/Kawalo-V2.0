import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

/// Molecule widget untuk pilihan opsi modal (decision/source picker)
/// berstandar Material 3 Expressive (misal: Kamera, Galeri, Lokasi GPS,
/// Pilih di Peta).
///
/// Menggunakan [AppCard] berbingkai outlined dengan kontainer sirkular
/// untuk ikon utama, tipografi berjenjang, dan chevron navigasi.
class AppOptionTile extends StatelessWidget {
  /// Membuat instance [AppOptionTile].
  const AppOptionTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.vectorIcon,
    super.key,
    this.iconColor,
    this.containerColor,
    this.trailing,
    this.semanticLabel,
    this.padding,
  });

  /// Judul opsi utama (menggunakan emphasized titleSmall).
  final String title;

  /// Subjudul deskriptif opsi (menggunakan bodySmall).
  final String subtitle;

  /// Callback saat kartu opsi diketuk.
  final VoidCallback onTap;

  /// Aset SVG vektor untuk ikon opsi.
  final String vectorIcon;

  /// Warna ikon SVG (default: `colorScheme.onPrimaryContainer`).
  final Color? iconColor;

  /// Warna latar kontainer sirkular ikon
  /// (default: `colorScheme.primaryContainer`).
  final Color? containerColor;

  /// Widget akhiran opsional
  /// (default: chevron panah kanan [KawaloVectors.arrowRight01]).
  final Widget? trailing;

  /// Label semantik untuk pembaca layar (opsional).
  final String? semanticLabel;

  /// Padding internal kartu (default: horizontal 16dp, vertical 12dp).
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveContainerColor =
        containerColor ?? colorScheme.primaryContainer;
    final effectiveIconColor = iconColor ?? colorScheme.onPrimaryContainer;

    return AppCard(
      variant: AppCardVariant.outlined,
      onPressed: onTap,
      semanticLabel: semanticLabel ?? '$title: $subtitle',
      padding:
          padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.space200,
            vertical: AppSpacing.space150,
          ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppStateLayer.minTouchTarget,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: effectiveContainerColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppSvgIcon(
                  vectorIcon,
                  size: 22,
                  color: effectiveIconColor,
                ),
              ),
            ),
            AppSpacing.hGap200,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.typography.emphasized.titleSmall.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  AppSpacing.vGap25,
                  Text(
                    subtitle,
                    style: theme.typeScale.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.hGap100,
            trailing ??
                ExcludeSemantics(
                  child: AppSvgIcon(
                    KawaloVectors.arrowRight01,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
