import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';

/// Komponen atomik header untuk setiap seksi kartu atau formulir.
///
/// Menyediakan perenderan judul utama yang ditekankan, deskripsi subjudul,
/// dan slot aksi trailing di sisi kanan dengan keselarasan Material 3.
class AppSectionHeader extends StatelessWidget {
  /// Membuat instance [AppSectionHeader].
  const AppSectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.space50),
    super.key,
  });

  /// Judul seksi (misal: "Informasi tamu & identitas", "Detail publikasi").
  final String title;

  /// Subjudul deskripsi konteks seksi (opsional).
  final String? subtitle;

  /// Widget opsional di sisi kanan (misal: tombol aksi teks "Hapus semua").
  final Widget? trailing;

  /// Padding horizontal/vertikal pembungkus header.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.typography.emphasized.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (trailing != null) ...[AppSpacing.hGap150, trailing!],
            ],
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            AppSpacing.vGap50,
            Text(
              subtitle!,
              style: theme.typeScale.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
