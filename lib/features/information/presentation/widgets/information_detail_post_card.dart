import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/presentation/extensions/information_item_ui_extension.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/app_image_collage.dart';

/// Kartu postingan utama pada layar detail informasi
/// (`InformationDetailPostCard`).
///
/// Mengonsolidasikan identitas pengirim (avatar, nama, email), metadata feed
/// (tag kategori, waktu pembuatan), judul, isi narasi lengkap tanpa pemotongan,
/// dan banner kolase foto adaptif Material 3 Expressive.
class InformationDetailPostCard extends StatelessWidget {
  /// Membuat instance [InformationDetailPostCard].
  const InformationDetailPostCard({required this.item, super.key});

  /// Data feed informasi yang ditampilkan.
  final InformationItemEntity item;

  @override
  Widget build(BuildContext context) {
    final photoInfo = item.photos.isNotEmpty
        ? ', ${item.photos.length} foto terlampir'
        : '';
    final semanticLabel =
        'Postingan informasi ${item.displayTitle}, dibuat oleh '
        '${item.displayUserName} (${item.displayUserEmail}), tanggal '
        '${item.displayFeedDt}, kategori ${item.typeLabel}$photoInfo';

    return AppCard(
      semanticLabel: semanticLabel,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space150,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Header Postingan: Avatar, Nama Pengirim, & Email ───────
          _buildPostHeader(context),

          AppSpacing.vGapSm,

          // ── 2. Tag Kategori & Waktu Publikasi ────────────────────────
          _buildPostMeta(context),

          AppSpacing.vGapSm,

          // ── 3. Konten Utama: Judul & Narasi Lengkap ──────────────────
          _buildPostContent(context),

          // ── 4. Banner Kolase Foto (Jika Tersedia) ────────────────────
          if (item.photos.isNotEmpty) ...[
            AppSpacing.vGapSm,
            _buildMediaBanner(context),
          ],
        ],
      ),
    );
  }

  /// Membangun metadata postingan (Tag Kategori dan Waktu Pembuatan).
  Widget _buildPostMeta(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: AppSpacing.space100,
        runSpacing: AppSpacing.space100,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppTag(label: item.typeLabel, variant: item.typeVariant),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppSvgIcon.color(KawaloColorVectors.calendar1, size: 14),
              AppSpacing.hGapXs,
              Text(
                item.displayFeedDt,
                style: typeScale.labelSmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Membangun header pengirim postingan (Avatar, Nama Lengkap, dan Email).
  Widget _buildPostHeader(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;

    return Row(
      children: [
        _buildAvatar(context),
        AppSpacing.hGapSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.displayUserName,
                style: emphasizedTypeScale.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                item.displayUserEmail,
                style: typeScale.labelMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Membangun teks judul dan narasi lengkap postingan tanpa pemotongan baris.
  Widget _buildPostContent(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.displayTitle,
          style: emphasizedTypeScale.titleLarge.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        if (item.text != null && item.text!.isNotEmpty) ...[
          AppSpacing.vGap100,
          Text(
            item.text!,
            style: typeScale.bodyLarge.copyWith(color: colorScheme.onSurface),
          ),
        ],
      ],
    );
  }

  /// Membangun kolase foto adaptif Material 3 Expressive dengan tap ke viewer.
  Widget _buildMediaBanner(BuildContext context) {
    if (item.photos.isEmpty) return const SizedBox.shrink();

    return AppImageCollage(
      imageUrls: item.photos,
      heroTagPrefix: 'info_detail_${item.id}',
      onImageTap: (initialIndex) {
        AppImageViewer.show(
          context,
          imageUrls: item.photos,
          initialIndex: initialIndex,
          heroTagPrefix: 'info_detail_${item.id}',
        );
      },
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final pic = item.userProfilePic?.trim();
    final isNetworkUrl =
        pic != null &&
        (pic.startsWith('http://') || pic.startsWith('https://'));

    if (isNetworkUrl) {
      return ClipRRect(
        borderRadius: AppRadius.borderMedium,
        child: CachedNetworkImage(
          imageUrl: pic,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (_, _) => _buildAvatarFallback(),
          errorWidget: (_, _, _) => _buildAvatarFallback(),
        ),
      );
    }
    return _buildAvatarFallback();
  }

  Widget _buildAvatarFallback() {
    return const ClipRRect(
      borderRadius: AppRadius.borderMedium,
      child: AppSvgIcon.color(KawaloColorVectors.patrol3, size: 40),
    );
  }
}
