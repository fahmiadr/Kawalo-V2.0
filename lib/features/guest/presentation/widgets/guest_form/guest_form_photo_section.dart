import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_form_empty_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_image_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_morphing_surface.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_state.dart';
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';

class GuestFormPhotoSection extends StatelessWidget {
  const GuestFormPhotoSection({
    required this.cubit,
    required this.isSubmitting,
    required this.onPickPhoto,
    super.key,
  });

  final GuestFormCubit cubit;
  final bool isSubmitting;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;

    return BlocSelector<GuestFormCubit, GuestFormState,
        ({InformationFormMediaItem? photoMedia, String? photoUrl})>(
      selector: (state) => (
        photoMedia: state.photoMedia,
        photoUrl: state.photoUrl,
      ),
      builder: (context, photoState) {
        final photoMedia = photoState.photoMedia;
        final photoUrl = photoState.photoUrl;
        final hasPhoto = photoMedia != null ||
            (photoUrl != null && photoUrl.trim().isNotEmpty);

        if (!hasPhoto) {
          return AppFormEmptyPlaceholder(
            title: 'Lampirkan Foto Tamu',
            subtitle: 'Ketuk untuk mengambil foto kamera atau galeri',
            vectorIcon: KawaloVectors.camera01,
            onTap: isSubmitting ? null : onPickPhoto,
          );
        }

        // Render photo thumbnail with Hero transition to AppImageViewer
        final displaySource =
            photoMedia != null ? photoMedia.displaySource : photoUrl!;

        Widget imageContent;
        final mediaPath = photoMedia?.path;
        if (photoMedia?.bytes != null) {
          imageContent = Image.memory(
            photoMedia!.bytes!,
            fit: BoxFit.cover,
          );
        } else if (!kIsWeb &&
            mediaPath != null &&
            File(mediaPath).existsSync()) {
          imageContent = Image.file(
            File(mediaPath),
            fit: BoxFit.cover,
          );
        } else if (displaySource.startsWith('http://') ||
            displaySource.startsWith('https://')) {
          imageContent = CachedNetworkImage(
            imageUrl: displaySource,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (_, __) => const AppImagePlaceholder(
              icon: AppLoadingIndicator(
                size: AppLoadingIndicatorSize.small,
              ),
            ),
            errorWidget: (_, __, ___) => const AppImagePlaceholder(
              iconSize: 24,
            ),
          );
        } else {
          imageContent = const AppImagePlaceholder(
            iconPath: KawaloVectors.images,
            iconSize: 24,
          );
        }

        return AppCard(
          variant: AppCardVariant.outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 180,
                child: AppMorphingSurface(
                  onTap: () {
                    AppImageViewer.show(
                      context,
                      imageUrls: [displaySource],
                      heroTagPrefix: 'guest_form_photo',
                    );
                  },
                  semanticLabel: 'Lihat foto tamu layar penuh',
                  overlay: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Tombol Hapus Silang Cepat di Kanan Atas
                      Positioned(
                        top: AppSpacing.space100,
                        right: AppSpacing.space100,
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: AppIconButton(
                            onPressed:
                                isSubmitting ? null : cubit.onRemovePhoto,
                            semanticLabel: 'Hapus foto tamu',
                            size: AppIconButtonSize.xs,
                            decoration: M3EIconButtonDecoration(
                              backgroundColor: WidgetStatePropertyAll(
                                colorScheme.scrim.withValues(alpha: 0.60),
                              ),
                              foregroundColor: const WidgetStatePropertyAll(
                                Colors.white,
                              ),
                              side: WidgetStatePropertyAll(
                                BorderSide(
                                  color: Colors.white.withValues(alpha: 0.30),
                                ),
                              ),
                            ),
                            icon: const AppSvgIcon(
                              KawaloVectors.cancel01,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  child: Hero(
                    tag: 'guest_form_photo_0',
                    child: imageContent,
                  ),
                ),
              ),
              AppSpacing.vGap150,
              AppButton(
                style: AppButtonColor.outlined,
                enabled: !isSubmitting,
                onPressed: onPickPhoto,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppSvgIcon(KawaloVectors.camera01, size: 18),
                    AppSpacing.hGapXs,
                    Text('Ganti Foto'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
