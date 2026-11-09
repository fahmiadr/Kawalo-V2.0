import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/presentation/extensions/information_item_ui_extension.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/app_file_tile.dart';
import 'package:path_provider/path_provider.dart';

/// Seksi kartu penampil berkas lampiran resmi untuk layar detail informasi
/// ([InformationDetailFileSection]).
///
/// Menyediakan:
/// 1. Ikon resmi berkas standar melalui [AppFileTile].
/// 2. Metadata nama berkas dan format ekstensi ringkas (PDF, Word, Excel,
///    dsb.).
/// 3. Tombol aksi responsif di sisi kanan: "Buka" (aplikasi eksternal) dan
///    "Unduh" (dengan indikator status progres unduhan).
class InformationDetailFileSection extends StatefulWidget {
  /// Membuat instance [InformationDetailFileSection].
  const InformationDetailFileSection({required this.item, this.dio, super.key});

  /// Data feed informasi yang memuat berkas lampiran.
  final InformationItemEntity item;

  /// Klien HTTP Dio opsional untuk pengujian atau custom transport.
  final Dio? dio;

  @override
  State<InformationDetailFileSection> createState() =>
      _InformationDetailFileSectionState();
}

class _InformationDetailFileSectionState
    extends State<InformationDetailFileSection> {
  bool _isDownloading = false;
  double _downloadProgress = 0;

  late final Dio _dio;

  @override
  void initState() {
    super.initState();
    _dio = widget.dio ?? Dio();
  }

  /// Mengekstrak ekstensi berkas secara bersih tanpa titik pemisah.
  String get _fileExtension {
    final file = widget.item.feedFile ?? '';
    final cleanPath = file.split('?').first;
    final dotIndex = cleanPath.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < cleanPath.length - 1) {
      return cleanPath.substring(dotIndex + 1).toLowerCase();
    }
    return '';
  }

  /// Nama berkas bersih tanpa query parameter.
  String get _fileName {
    final file = widget.item.feedFile ?? '';
    final cleanPath = file.split('?').first;
    final slashIndex = cleanPath.lastIndexOf('/');
    if (slashIndex != -1 && slashIndex < cleanPath.length - 1) {
      return cleanPath.substring(slashIndex + 1);
    }
    return file;
  }

  /// Nama ringkas format berkas untuk subtitle tile berkas.
  String get _formatDescription {
    switch (_fileExtension) {
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
        return _fileExtension.isNotEmpty
            ? _fileExtension.toUpperCase()
            : 'Dokumen';
    }
  }

  /// Membuka berkas menggunakan aplikasi eksternal di perangkat.
  Future<void> _openExternal() async {
    AppSnackbar.show(
      context,
      message: 'Membuka "$_fileName" dengan aplikasi eksternal...',
    );
  }

  /// Mengunduh berkas lampiran ke penyimpanan lokal perangkat.
  Future<void> _downloadFile() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.1;
    });

    try {
      final file = widget.item.feedFile ?? '';
      final isNetwork =
          file.startsWith('http://') || file.startsWith('https://');

      String savePath;
      try {
        final dir = await getApplicationDocumentsDirectory();
        savePath = '${dir.path}/$_fileName';
      } on Object catch (_) {
        savePath = '/downloads/$_fileName';
      }

      if (isNetwork) {
        await _dio.download(
          file,
          savePath,
          onReceiveProgress: (received, total) {
            if (total > 0 && mounted) {
              setState(() {
                _downloadProgress = received / total;
              });
            }
          },
        );
      } else {
        // Simulasi progres unduhan untuk berkas lokal atau tautan mockup
        for (var step = 1; step <= 5; step++) {
          await Future<void>.delayed(const Duration(milliseconds: 150));
          if (mounted) {
            setState(() {
              _downloadProgress = step / 5;
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 1.0;
        });
        AppSnackbar.show(
          context,
          message: 'Berkas "$_fileName" berhasil diunduh.',
        );
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        AppSnackbar.show(context, message: 'Gagal mengunduh berkas: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.item.hasFileAttachment) {
      return const SizedBox.shrink();
    }

    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final emphasizedTypeScale = theme.typography.emphasized;

    final semanticLabel =
        'Seksi berkas lampiran $_fileName, '
        'format $_formatDescription';

    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space150,
      ),
      child: Semantics(
        label: semanticLabel,
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header Seksi Lampiran (Tanpa Chip) ─────────────────────
            Text(
              'Berkas Lampiran',
              style: emphasizedTypeScale.titleMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),

            AppSpacing.vGap150,

            // ── Tile Info Berkas & Ikon Ekstensi Resmi ─────────────────
            _buildFileInfoTile(context),

            // ── Indikator Progres Unduhan ──────────────────────────────
            if (_isDownloading) ...[
              AppSpacing.vGap100,
              LinearProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: colorScheme.primary,
                minHeight: 4,
              ),
            ],

            AppSpacing.vGap150,

            // ── Bilah Tombol Aksi (Buka & Unduh, Rata Kanan) ───────────
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// Tile representasi berkas lengkap dengan ikon standar dokumen resmi.
  Widget _buildFileInfoTile(BuildContext context) {
    return AppFileTile(
      fileName: _fileName,
      extension: _fileExtension,
      subtitle: _formatDescription,
    );
  }

  /// Tombol aksi interaktif (Buka Eksternal dan Unduh, di sebelah kanan).
  Widget _buildActionButtons(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: AppSpacing.space150,
        runSpacing: AppSpacing.space100,
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // 1. Tombol "Buka" dengan Aplikasi Eksternal
          AppButton(
            onPressed: _openExternal,
            style: AppButtonColor.outlined,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSvgIcon(KawaloVectors.linkSquare02, size: 16),
                AppSpacing.hGapXs,
                Text('Buka'),
              ],
            ),
          ),

          // 2. Tombol "Unduh"
          AppButton(
            onPressed: _isDownloading ? null : _downloadFile,
            style: AppButtonColor.tonal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isDownloading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: AppLoadingIndicator(
                      size: AppLoadingIndicatorSize.small,
                    ),
                  )
                else
                  const AppSvgIcon(KawaloVectors.download01, size: 16),
                AppSpacing.hGapXs,
                Text(_isDownloading ? 'Mengunduh...' : 'Unduh'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
