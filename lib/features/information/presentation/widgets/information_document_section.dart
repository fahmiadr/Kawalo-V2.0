import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_file_tile.dart';
import 'package:kawalo_mobile/core/widgets/app_form_empty_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_form_section.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_state.dart';
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';

/// Organism seksi dokumen lampiran (maksimal 1 berkas).
class InformationDocumentSection extends StatelessWidget {
  /// Membuat instance [InformationDocumentSection].
  const InformationDocumentSection({
    required this.isSubmitting,
    required this.onPickDocument,
    required this.onClearDocument,
    super.key,
  });

  /// Status proses submit formulir.
  final bool isSubmitting;

  /// Callback untuk memilih dokumen dari penyimpanan perangkat.
  final VoidCallback onPickDocument;

  /// Callback untuk menghapus dokumen yang terpasang.
  final VoidCallback onClearDocument;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocSelector<InformationFormCubit, InformationFormState,
        ({InformationFormMediaItem? doc, String feedFile, String? error})>(
      selector: (state) => (
        doc: state.documentMedia,
        feedFile: state.feedFile,
        error: state.feedFileError,
      ),
      builder: (context, data) {
        final hasDocument = data.doc != null || data.feedFile.isNotEmpty;
        final docName = data.doc?.name ?? data.feedFile;

        return AppFormSection.uncontained(
          title: 'Dokumen lampiran (maksimal 1)',
          subtitle: 'Lampirkan dokumen pendukung.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!hasDocument)
                AppFormEmptyPlaceholder(
                  title: 'Belum ada dokumen',
                  subtitle: 'Ketuk untuk memilih dokumen pendukung '
                      '(PDF, Word, Excel)',
                  vectorIcon: KawaloVectors.documentAttachment,
                  onTap: isSubmitting ? null : onPickDocument,
                )
              else ...[
                  AppFileTile(
                    fileName: docName,
                  ),
                  AppSpacing.vGap150,

                  // Tombol Aksi: Ubah & Hapus
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: AppSpacing.space150,
                      runSpacing: AppSpacing.space100,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AppButton(
                          style: AppButtonColor.outlined,
                          onPressed: isSubmitting ? null : onPickDocument,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppSvgIcon(
                                KawaloVectors.edit03,
                                size: 16,
                              ),
                              AppSpacing.hGapXs,
                              Text('Ubah berkas'),
                            ],
                          ),
                        ),
                        AppButton(
                          style: AppButtonColor.text,
                          onPressed: isSubmitting ? null : onClearDocument,
                          semanticLabel: 'Hapus dokumen',
                          decoration: AppButtonDecoration(
                            foregroundColor: WidgetStatePropertyAll<Color?>(
                              colorScheme.error,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppSvgIcon(
                                KawaloVectors.delete01,
                                size: 16,
                              ),
                              AppSpacing.hGapXs,
                              Text('Hapus berkas'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (data.error != null) ...[
                  AppSpacing.vGap100,
                  Text(
                    data.error!,
                    style: theme.typeScale.bodySmall.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
        );
      },
    );
  }
}
