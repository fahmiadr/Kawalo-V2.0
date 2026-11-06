import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_form_empty_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_form_section.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_state.dart';
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_photo_thumbnail.dart';

/// Organism seksi dokumentasi foto (Grid 2-kolom, placeholder kosong,
/// badge urutan, dan tombol tambah foto).
class InformationPhotosSection extends StatelessWidget {
  /// Membuat instance [InformationPhotosSection].
  const InformationPhotosSection({
    required this.isSubmitting,
    required this.onPickPhoto,
    required this.onClearAll,
    required this.onTapPhoto,
    required this.onRemovePhoto,
    required this.onMoreOptions,
    this.heroTagPrefix = 'info_form_photo',
    super.key,
  });

  /// Status proses submit formulir.
  final bool isSubmitting;

  /// Prefiks untuk kalkulasi Hero tag animasi transisi spasial.
  /// Default bernilai `'info_form_photo'`.
  final String heroTagPrefix;

  /// Callback untuk memicu pemilihan foto baru.
  final VoidCallback onPickPhoto;

  /// Callback untuk menghapus seluruh foto lampiran.
  final VoidCallback onClearAll;

  /// Callback saat foto ke-index diketuk (buka di ImageViewer).
  final void Function(int index) onTapPhoto;

  /// Callback saat foto ke-index dihapus via tombol silang.
  final void Function(int index) onRemovePhoto;

  /// Callback saat tombol menu titik tiga pada foto ke-index diketuk.
  final void Function(int index) onMoreOptions;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocSelector<InformationFormCubit, InformationFormState,
        ({List<InformationFormMediaItem> photos, String? error})>(
      selector: (state) => (
        photos: state.photos,
        error: state.photosError,
      ),
      builder: (context, data) {
        final photos = data.photos;
        final hasLoadingPhotos = photos.any((p) => p.isLoading);
        final canAddPhoto = !isSubmitting && !hasLoadingPhotos;

        return AppFormSection.uncontained(
          title: 'Dokumentasi foto (${photos.length}/4)',
          subtitle: 'Tambahkan hingga 4 foto dari kamera atau galeri.',
          trailing: photos.isNotEmpty
              ? AppButton(
                  style: AppButtonColor.text,
                  size: AppButtonSize.xs,
                  enabled: !isSubmitting && !hasLoadingPhotos,
                  onPressed: (isSubmitting || hasLoadingPhotos)
                      ? null
                      : onClearAll,
                  semanticLabel: 'Hapus semua foto',
                  decoration: AppButtonDecoration(
                    foregroundColor: WidgetStatePropertyAll<Color?>(
                      colorScheme.error,
                    ),
                  ),
                  child: const Text('Hapus semua'),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                if (photos.isEmpty)
                  AppFormEmptyPlaceholder(
                    title: 'Belum ada foto terlampir',
                    subtitle:
                        'Ketuk untuk memilih foto dari kamera atau galeri',
                    vectorIcon: KawaloVectors.images,
                    onTap: isSubmitting ? null : onPickPhoto,
                  )
                else ...[
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSpacing.space150,
                      mainAxisSpacing: AppSpacing.space150,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final item = photos[index];
                      return InformationPhotoThumbnail(
                        item: item,
                        index: index,
                        heroTagPrefix: heroTagPrefix,
                        isSubmitting: isSubmitting,
                        onTap: () => onTapPhoto(index),
                        onRemove: () => onRemovePhoto(index),
                        onMoreOptions: () => onMoreOptions(index),
                      );
                    },
                  ),
                  if (photos.length < 4) ...[
                    AppSpacing.vGap200,
                    AppButton(
                      style: AppButtonColor.outlined,
                      enabled: canAddPhoto,
                      onPressed: canAddPhoto ? onPickPhoto : null,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppSvgIcon(
                            KawaloVectors.add01,
                            size: 18,
                          ),
                          AppSpacing.hGapXs,
                          Text('Tambah foto'),
                        ],
                      ),
                    ),
                  ],
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
