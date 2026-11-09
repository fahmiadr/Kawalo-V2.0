import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

/// Data model untuk item kartu pintasan (shortcut).
class AppShortcutItem {
  /// Membuat instance [AppShortcutItem].
  const AppShortcutItem({
    required this.title,
    required this.iconPath,
    this.subtitle,
    this.badgeText,
    this.semanticLabel,
    this.onTap,
  });

  /// Judul pintasan (misal: "Jadwal Kerja", "Data Tamu", dll).
  final String title;

  /// Keterangan atau status ringkas (misal: "Masuk 30 Jun 2026 08:00").
  final String? subtitle;

  /// Path aset SVG/PNG ikon berwarna.
  final String iconPath;

  /// Teks badge atau penanda khusus di sudut kanan atas (misal: "BARU!").
  final String? badgeText;

  /// Label semantik untuk aksesibilitas pembaca layar.
  final String? semanticLabel;

  /// Aksi ketika pintasan ditekan.
  final VoidCallback? onTap;
}

/// Konfigurasi ukuran visual untuk [AppShortcutCard].
enum AppShortcutCardSize {
  /// Ukuran standar (default, 2 kolom pada beranda):
  /// Ikon 40dp, padding 12dp, tipografi titleSmall.
  regular,

  /// Ukuran ringkas (4 kolom pada halaman informasi sesuai Figma):
  /// Ikon 24dp, padding horizontal 8dp & vertikal 12dp, tipografi labelSmall.
  compact,
}

/// Komponen kartu individual untuk item pintasan menggunakan [AppCard].
class AppShortcutCard extends StatelessWidget {
  /// Membuat instance [AppShortcutCard].
  const AppShortcutCard({
    required this.item,
    super.key,
    this.size = AppShortcutCardSize.regular,
  });

  /// Data pintasan yang ditampilkan pada kartu.
  final AppShortcutItem item;

  /// Konfigurasi ukuran kartu (default: [AppShortcutCardSize.regular]).
  final AppShortcutCardSize size;

  /// Menandakan apakah kartu menggunakan konfigurasi ukuran ringkas.
  bool get isCompact => size == AppShortcutCardSize.compact;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;

    final effectiveSemanticLabel = item.semanticLabel ??
        (item.subtitle != null && item.subtitle!.isNotEmpty
            ? '${item.title}, ${item.subtitle}'
            : item.title);

    final cardPadding = isCompact
        ? const EdgeInsets.symmetric(
            horizontal: AppSpacing.space75,
            vertical: AppSpacing.space100,
          )
        : const EdgeInsets.symmetric(
            horizontal: AppSpacing.space200,
            vertical: AppSpacing.space150,
          );

    final iconSize = isCompact ? 24.0 : 40.0;

    final titleStyle = isCompact
        ? emphasizedTypeScale.labelSmall.copyWith(
            fontSize: 10,
            height: 1.15,
            letterSpacing: 0,
            color: colorScheme.onSurface,
          )
        : emphasizedTypeScale.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          );

    return AppCard(
      onPressed: item.onTap,
      semanticLabel: effectiveSemanticLabel,
      padding: cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Baris Atas: Ikon di Kiri Atas & Badge Opsional ────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSvgIcon.color(
                item.iconPath,
                size: iconSize,
                semanticLabel: item.title,
              ),
              if (item.badgeText != null && item.badgeText!.isNotEmpty) ...[
                AppSpacing.hGap200,
                Flexible(
                  child: Text(
                    item.badgeText!,
                    textAlign: TextAlign.right,
                    style: emphasizedTypeScale.labelLarge.copyWith(
                      color: colorScheme.info,
                    ),
                  ),
                ),
              ],
            ],
          ),

          AppSpacing.vGapSm,

          // ── Baris Bawah: Judul Rata Atas, Ruang Kosong di Bawah ───────────
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: titleStyle,
                  maxLines: item.subtitle != null && item.subtitle!.isNotEmpty
                      ? 1
                      : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                  AppSpacing.vGap25,
                  Text(
                    item.subtitle!,
                    style: typeScale.labelMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu khusus aksi tambah item sesuai rancangan Figma Card2.
class AppAddShortcutCard extends StatelessWidget {
  /// Membuat instance [AppAddShortcutCard].
  const AppAddShortcutCard({
    super.key,
    this.label = 'Tambah Pintasan',
    this.onPressed,
    this.semanticLabel,
  });

  /// Teks label kartu aksi tambah (misal: "Tambah Pintasan" / "Tambah Manajemen").
  final String label;

  /// Callback saat kartu ditekan.
  final VoidCallback? onPressed;

  /// Label semantik untuk aksesibilitas.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final emphasizedTypeScale = theme.typography.emphasized;
    final effectiveSemanticLabel = semanticLabel ?? label;

    return AppCard(
      variant: AppCardVariant.filled,
      color: colorScheme.secondaryContainer,
      onPressed: onPressed,
      semanticLabel: effectiveSemanticLabel,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space150,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon(
              KawaloVectors.addCircleFilled,
              size: 40,
              color: colorScheme.onSecondaryContainer,
            ),
            AppSpacing.vGapSm,
            Text(
              label,
              textAlign: TextAlign.center,
              style: emphasizedTypeScale.titleMedium.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
