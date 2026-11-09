import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/file_download_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/file_download_state.dart';
import 'package:kawalo_mobile/features/information/presentation/extensions/information_item_ui_extension.dart';
import 'package:kawalo_mobile/features/information/presentation/utils/attachment_file_info.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/app_file_tile.dart';

/// Seksi kartu penampil berkas lampiran resmi untuk layar detail informasi
/// ([InformationDetailFileSection]).
///
/// Menyediakan:
/// 1. Ikon resmi berkas standar melalui [AppFileTile].
/// 2. Metadata nama berkas dan format ekstensi ringkas (PDF, Word, Excel,
///    dsb.).
/// 3. Tombol aksi responsif di sisi kanan: "Buka" (aplikasi eksternal) dan
///    "Unduh" (dengan indikator status progres unduhan).
class InformationDetailFileSection extends StatelessWidget {
  /// Membuat instance [InformationDetailFileSection].
  const InformationDetailFileSection({required this.item, this.dio, super.key});

  /// Data feed informasi yang memuat berkas lampiran.
  final InformationItemEntity item;

  /// Klien HTTP Dio opsional untuk pengujian atau custom transport.
  final Dio? dio;

  /// Membuka berkas menggunakan aplikasi eksternal di perangkat.
  Future<void> _openExternal(BuildContext context) async {
    AppSnackbar.show(
      context,
      message:
          'Membuka "${attachmentFileName(item.feedFile ?? '')}" '
          'dengan aplikasi eksternal...',
    );
  }

  void _onDownloadState(BuildContext context, FileDownloadState state) {
    switch (state) {
      case FileDownloadDone():
        AppSnackbar.show(
          context,
          message:
              'Berkas "${attachmentFileName(item.feedFile ?? '')}" '
              'berhasil diunduh.',
        );
      case FileDownloadFailure(:final message):
        AppSnackbar.show(context, message: message);
      case FileDownloadIdle() || FileDownloadInProgress():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!item.hasFileAttachment) {
      return const SizedBox.shrink();
    }

    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final emphasizedTypeScale = theme.typography.emphasized;

    final file = item.feedFile ?? '';
    final fileName = attachmentFileName(file);
    final formatDescription = attachmentFormatLabel(file);

    final semanticLabel =
        'Seksi berkas lampiran $fileName, '
        'format $formatDescription';

    return BlocProvider(
      create: (_) => FileDownloadCubit(dio ?? Dio()),
      child: BlocConsumer<FileDownloadCubit, FileDownloadState>(
        listener: _onDownloadState,
        builder: (context, state) {
          final isDownloading = state is FileDownloadInProgress;
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
                  // ── Header Seksi Lampiran (Tanpa Chip) ─────────────────
                  Text(
                    'Berkas Lampiran',
                    style: emphasizedTypeScale.titleMedium.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),

                  AppSpacing.vGap150,

                  // ── Tile Info Berkas & Ikon Ekstensi Resmi ─────────────
                  AppFileTile(
                    fileName: fileName,
                    extension: attachmentFileExtension(file),
                    subtitle: formatDescription,
                  ),

                  // ── Indikator Progres Unduhan ──────────────────────────
                  if (state case FileDownloadInProgress(:final progress)) ...[
                    AppSpacing.vGap100,
                    LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: colorScheme.primary,
                      minHeight: 4,
                    ),
                  ],

                  AppSpacing.vGap150,

                  // ── Bilah Tombol Aksi (Buka & Unduh, Rata Kanan) ───────
                  _buildActionButtons(context, isDownloading, file),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Tombol aksi interaktif (Buka Eksternal dan Unduh, di sebelah kanan).
  Widget _buildActionButtons(
    BuildContext context,
    bool isDownloading,
    String file,
  ) {
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
            onPressed: () => _openExternal(context),
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
            onPressed: isDownloading
                ? null
                : () => unawaited(
                    context.read<FileDownloadCubit>().download(file),
                  ),
            style: AppButtonColor.tonal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDownloading)
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
                Text(isDownloading ? 'Mengunduh...' : 'Unduh'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
