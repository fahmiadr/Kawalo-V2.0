import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_file_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tooltip.dart';

/// Komponen visual standar Material 3 Expressive untuk menampilkan
/// representasi kartu/tile dokumen lampiran ([AppFileTile]).
///
/// Menyediakan:
/// 1. Ikon resmi badge berkas standar via [AppFileIcon].
/// 2. Nama berkas dengan [AppTooltip] saat teks terpotong (*ellipsis*).
/// 3. Subtitle ringkas format ekstensi (PDF, Word, Excel, dsb.).
/// 4. Slot [trailing] opsional untuk komponen aksi kustom di sisi kanan baris.
class AppFileTile extends StatelessWidget {
  /// Membuat instance [AppFileTile].
  const AppFileTile({
    required this.fileName,
    this.extension,
    this.subtitle,
    this.trailing,
    super.key,
  });

  /// Nama berkas lengkap (misal: 'laporan_kegiatan.pdf').
  final String fileName;

  /// Ekstensi berkas opsional. Jika null, akan diekstrak otomatis dari
  /// [fileName].
  final String? extension;

  /// Subtitle format berkas opsional (misal: 'PDF', 'Word', 'Excel').
  /// Jika null, akan di-resolve otomatis dari ekstensi berkas.
  final String? subtitle;

  /// Widget opsional di sisi kanan baris tile.
  final Widget? trailing;

  /// Mengekstrak ekstensi berkas secara bersih tanpa query parameter atau
  /// titik.
  static String extractExtension(String file) {
    final cleanPath = file.split('?').first;
    final dotIndex = cleanPath.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < cleanPath.length - 1) {
      return cleanPath.substring(dotIndex + 1).toLowerCase();
    }
    return '';
  }

  /// Mengekstrak nama berkas bersih dari path atau URL.
  static String extractFileName(String file) {
    final cleanPath = file.split('?').first;
    final slashIndex = cleanPath.lastIndexOf('/');
    if (slashIndex != -1 && slashIndex < cleanPath.length - 1) {
      return cleanPath.substring(slashIndex + 1);
    }
    return cleanPath;
  }

  /// Format deskripsi ringkas berdasarkan ekstensi berkas.
  static String formatDescriptionOf(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'PDF';
      case 'doc':
      case 'docx':
        return 'Word';
      case 'xls':
      case 'xlsx':
        return 'Excel';
      case 'ppt':
      case 'pptx':
        return 'PowerPoint';
      case 'csv':
        return 'CSV';
      case 'txt':
        return 'Text';
      case 'json':
        return 'JSON';
      case 'xml':
        return 'XML';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
        return 'Image';
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
        return 'Archive';
      default:
        return ext.isNotEmpty ? ext.toUpperCase() : 'Dokumen';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;

    final resolvedExtension = (extension != null && extension!.isNotEmpty)
        ? extension!
        : extractExtension(fileName);

    final resolvedFileName = extractFileName(fileName);

    final resolvedSubtitle = (subtitle != null && subtitle!.isNotEmpty)
        ? subtitle!
        : formatDescriptionOf(resolvedExtension);

    return Container(
      padding: AppSpacing.paddingAll150,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: AppRadius.borderMedium,
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          // Ikon Berkas Standar Resmi
          AppFileIcon(extension: resolvedExtension),

          AppSpacing.hGap150,

          // Metadata Nama & Format Ekstensi Ringkas
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTooltip(
                  message: resolvedFileName,
                  child: Text(
                    resolvedFileName,
                    style: emphasizedTypeScale.labelLarge.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppSpacing.vGap25,
                Text(
                  resolvedSubtitle,
                  style: typeScale.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          if (trailing != null) ...[
            AppSpacing.hGap150,
            trailing!,
          ],
        ],
      ),
    );
  }
}
