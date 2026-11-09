import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_image_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/presentation/extensions/guest_ui_extension.dart';

/// Kartu profil dan identitas tamu pada layar detail tamu.
///
/// Memuat foto/avatar tamu, nama, nomor tamu, tag identitas,
/// alamat asal, serta kode akses QR dengan aksi salin ke papan klip.
class GuestDetailProfileCard extends StatelessWidget {
  /// Membuat instance [GuestDetailProfileCard].
  const GuestDetailProfileCard({required this.item, super.key});

  /// Data tamu yang ditampilkan.
  final GuestItemEntity item;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedScale = theme.typography.emphasized;

    final semanticLabel =
        'Profil dan identitas tamu ${item.displayName}, nomor tamu '
        '${item.displayGuestNumber}, ${item.displayIdentityType} '
        '${item.displayIdNumber}';

    return AppCard(
      semanticLabel: semanticLabel,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space150,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Baris Header: Foto 100x100, Nama, Nomor Tamu, & Tags
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(context),
              AppSpacing.hGap200,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.displayName,
                      style: emphasizedScale.titleLarge.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.vGap25,
                    Text(
                      'No. tamu: ${item.displayGuestNumber}',
                      style: typeScale.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.vGapSm,
                    Wrap(
                      spacing: AppSpacing.space50,
                      runSpacing: AppSpacing.space50,
                      children: [
                        AppTag(
                          label:
                              '${item.displayIdentityType}: '
                              '${item.displayIdNumber}',
                          size: AppTagSize.small,
                        ),
                        if (item.displayCategory != '-')
                          AppTag(
                            label: item.displayCategory,
                            variant: AppTagVariant.secondary,
                            size: AppTagSize.small,
                          ),
                        AppTag(
                          label: item.displayGuestType,
                          variant: AppTagVariant.tertiary,
                          size: AppTagSize.small,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Pemisah Alamat Asal
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.space150),
            child: AppDivider(),
          ),

          // Alamat Asal
          Text(
            'Alamat asal',
            style: typeScale.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGap25,
          Text(
            item.displayAddress,
            style: emphasizedScale.bodyLarge.copyWith(
              color: colorScheme.onSurface,
            ),
          ),

          // Pemisah Kode Akses QR
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.space150),
            child: AppDivider(),
          ),

          // Kode Akses QR & Tombol Salin Kode
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Kode akses QR',
                      style: typeScale.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.vGap25,
                    Text(
                      item.displayQrUid,
                      style: emphasizedScale.bodyLarge.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AppSpacing.hGapSm,
              AppButton.icon(
                style: AppButtonColor.outlined,
                shape: AppButtonShape.square,
                semanticLabel: 'Salin kode akses QR',
                onPressed: (item.qrUid != null && item.qrUid!.isNotEmpty)
                    ? () async {
                        await Clipboard.setData(
                          ClipboardData(text: item.displayQrUid),
                        );
                        if (context.mounted) {
                          AppSnackbar.show(
                            context,
                            message: 'Kode akses QR disalin ke papan klip.',
                          );
                        }
                      }
                    : null,
                icon: const AppSvgIcon(KawaloVectors.copy),
                label: const Text('Salin kode'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final pic = item.guestPhoto?.trim();
    final isNetworkUrl =
        pic != null &&
        (pic.startsWith('http://') || pic.startsWith('https://'));

    if (isNetworkUrl) {
      final heroTagPrefix = 'guest_profile_${item.id}';

      return AppTappable(
        semanticLabel:
            'Lihat foto profil tamu ${item.displayName} ukuran '
            'penuh',
        excludeSemantics: true,
        onTap: () {
          AppImageViewer.show(
            context,
            imageUrls: [pic],
            heroTagPrefix: heroTagPrefix,
          );
        },
        child: ClipRRect(
          borderRadius: AppRadius.borderMedium,
          child: Hero(
            tag: '${heroTagPrefix}_0',
            child: CachedNetworkImage(
              imageUrl: pic,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              placeholder: (_, _) => _buildAvatarFallback(),
              errorWidget: (_, _, _) => _buildAvatarFallback(),
            ),
          ),
        ),
      );
    }

    return _buildAvatarFallback();
  }

  Widget _buildAvatarFallback() {
    return const AppImagePlaceholder(
      width: 100,
      height: 100,
      borderRadius: AppRadius.borderMedium,
      semanticLabel: 'Foto tamu tidak tersedia',
    );
  }
}
