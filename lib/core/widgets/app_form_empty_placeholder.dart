import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

/// Komponen molekul kartu placeholder interaktif untuk kondisi kosong
/// atau slot lampiran pada formulir (Foto, Dokumen, Titik Lokasi Peta).
class AppFormEmptyPlaceholder extends StatelessWidget {
  /// Membuat instance [AppFormEmptyPlaceholder].
  const AppFormEmptyPlaceholder({
    required this.title,
    required this.subtitle,
    this.onTap,
    this.vectorIcon,
    this.icon,
    this.iconWidget,
    this.isLoading = false,
    this.padding = const EdgeInsets.all(AppSpacing.space300),
    super.key,
  });

  /// Judul kondisi kosong (misal: "Belum ada foto terlampir").
  final String title;

  /// Petunjuk aksi untuk pengguna (misal: "Ketuk untuk memilih foto...").
  final String subtitle;

  /// Callback interaksi saat area placeholder diketuk.
  final VoidCallback? onTap;

  /// Aset SVG vektor untuk ikon utama placeholder.
  final String? vectorIcon;

  /// Alternatif Material [IconData] untuk ikon utama placeholder.
  final IconData? icon;

  /// Alternatif widget kustom untuk ikon placeholder.
  final Widget? iconWidget;

  /// Menandakan apakah sedang dalam proses pemuatan / resolusi asinkron.
  final bool isLoading;

  /// Padding bagian dalam kartu placeholder.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    Widget iconContent;
    if (isLoading) {
      iconContent = const SizedBox(
        width: 32,
        height: 32,
        child: AppLoadingIndicator(
          size: AppLoadingIndicatorSize.small,
        ),
      );
    } else if (iconWidget != null) {
      iconContent = iconWidget!;
    } else if (vectorIcon != null) {
      iconContent = AppSvgIcon(
        vectorIcon!,
        size: 32,
        color: colorScheme.primary,
      );
    } else if (icon != null) {
      iconContent = Icon(
        icon,
        size: 32,
        color: colorScheme.primary,
      );
    } else {
      iconContent = const SizedBox.shrink();
    }

    return AppCard(
      variant: AppCardVariant.outlined,
      onPressed: onTap,
      semanticLabel: '$title: $subtitle',
      padding: padding,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconContent,
            AppSpacing.vGap100,
            Text(
              title,
              style: theme.typography.emphasized.titleSmall.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGap25,
            Text(
              subtitle,
              style: theme.typeScale.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
