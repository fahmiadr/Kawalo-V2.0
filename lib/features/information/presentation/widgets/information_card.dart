import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/core/widgets/app_selection.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/presentation/extensions/information_item_ui_extension.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/app_image_collage.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_event_schedule.dart';

/// Komponen kartu feed informasi (`InformationCard`) yang mengimplementasikan
/// fondasi kartu resmi Kawalo ([AppCard]), Material 3 Expressive, dan
/// WCAG 2.1/2.2 AA.
class InformationCard extends StatelessWidget {
  /// Membuat instance [InformationCard].
  const InformationCard({
    required this.item,
    super.key,
    this.onTap,
    this.onLongPress,
    this.onEdit,
    this.currentUserSession,
    this.isOffline = false,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.isSelectable = true,
  });

  /// Data informasi / feed yang ditampilkan.
  final InformationItemEntity item;

  /// Callback ketika kartu ditekan.
  final VoidCallback? onTap;

  /// Callback ketika kartu ditekan lama (long press).
  final VoidCallback? onLongPress;

  /// Callback ketika tombol edit pada kartu ditekan.
  final VoidCallback? onEdit;

  /// Sesi autentikasi pengguna saat ini untuk verifikasi hak izin edit.
  final AuthSessionEntity? currentUserSession;

  /// Status apakah perangkat sedang berada dalam kondisi offline.
  final bool isOffline;

  /// Apakah kartu sedang berada dalam mode seleksi multi-item.
  final bool isSelectionMode;

  /// Status apakah kartu ini sedang dalam kondisi terpilih.
  final bool isSelected;

  /// Status apakah kartu ini berhak dipilih oleh pengguna aktif.
  final bool isSelectable;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    final photoInfo = item.photos.isNotEmpty
        ? ', ${item.photos.length} foto terlampir'
        : '';
    final fileInfo = item.hasFileAttachment ? ', berkas lampiran tersedia' : '';
    final selectedInfo = isSelected ? ', terpilih' : '';
    final semanticLabel =
        'Informasi ${item.displayTitle}, kategori ${item.typeLabel}, '
        'dibuat oleh ${item.displayUserName}, tanggal ${item.displayFeedDt}'
        '$fileInfo$photoInfo$selectedInfo';

    final effectiveCard = AppCard(
      onPressed: onTap,
      onLongPress: onLongPress,
      semanticLabel: semanticLabel,
      color: isSelected ? colorScheme.surfaceContainerHighest : null,
      border: isSelected
          ? BorderSide(color: colorScheme.primary, width: 2)
          : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space150,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Header Postingan: Avatar, Penulis, & Aksi Edit ─────────
          _buildPostHeader(context),

          AppSpacing.vGapSm,

          // ── 2. Tag Kategori, Lampiran, & Waktu Publikasi ────────────
          _buildPostMeta(context),
          InformationEventSchedule(item: item),

          AppSpacing.vGapSm,

          // ── 3. Konten Postingan: Judul & Narasi Laporan ─────────────
          _buildPostContent(context),

          // ── 4. Kolase Media Foto (Jika Tersedia) ───────────────────
          if (item.photos.isNotEmpty) ...[
            AppSpacing.vGapSm,
            _buildMediaBanner(context),
          ],
        ],
      ),
    );

    if (isSelectionMode && !isSelectable) {
      return Opacity(
        opacity: AppStateLayer.disabledOpacity,
        child: effectiveCard,
      );
    }

    return effectiveCard;
  }

  /// Membangun metadata postingan (Tag Kategori, Indikator Lampiran,
  /// dan Waktu Publikasi).
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
          Wrap(
            spacing: AppSpacing.space100,
            runSpacing: AppSpacing.space50,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppTag(label: item.typeLabel, variant: item.typeVariant),
              if (item.hasFileAttachment)
                const AppTag(
                  label: 'Lampiran',
                  variant: AppTagVariant.neutral,
                  leading: AppSvgIcon.color(
                    KawaloColorVectors.fileArchive,
                    size: 14,
                  ),
                ),
            ],
          ),
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

  /// Membangun header khas postingan (Avatar, Nama Pengirim, Email, dan
  /// aksi edit dinamis).
  Widget _buildPostHeader(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;

    final session = _resolveSession(context);
    final effectiveIsOffline = _resolveIsOffline(context);
    final canUpdate = item.canBeUpdatedBySession(session);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppStateLayer.minTouchTarget,
      ),
      child: Row(
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
          if (canUpdate && !isSelectionMode) ...[
            AppSpacing.hGapXs,
            AppIconButton(
              onPressed: effectiveIsOffline ? null : onEdit,
              tooltip: effectiveIsOffline
                  ? 'Tidak dapat mengedit saat offline'
                  : 'Edit informasi',
              semanticLabel: effectiveIsOffline
                  ? 'Edit informasi ${item.displayTitle} tidak '
                        'tersedia saat offline'
                  : 'Edit informasi ${item.displayTitle}',
              icon: AppSvgIcon(
                effectiveIsOffline
                    ? KawaloVectors.editOff03
                    : KawaloVectors.edit03,
                size: 20,
                color: effectiveIsOffline
                    ? colorScheme.onSurfaceVariant.withValues(
                        alpha: AppStateLayer.disabledOpacity,
                      )
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  AuthSessionEntity? _resolveSession(BuildContext context) {
    if (currentUserSession != null) return currentUserSession;
    try {
      return context.read<UserSessionCubit?>()?.state;
    } on Object catch (_) {
      return null;
    }
  }

  bool _resolveIsOffline(BuildContext context) {
    if (isOffline) return true;
    try {
      return context.read<ConnectivityCubit?>()?.state ==
          ConnectivityStatus.offline;
    } on Object catch (_) {
      return false;
    }
  }

  /// Membangun teks judul dan narasi postingan.
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
          style: emphasizedTypeScale.titleMedium.copyWith(
            color: colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (item.text != null && item.text!.isNotEmpty) ...[
          AppSpacing.vGap25,
          Text(
            item.text!,
            style: typeScale.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  /// Membangun kolase foto adaptif Material 3 Expressive.
  Widget _buildMediaBanner(BuildContext context) {
    if (item.photos.isEmpty) return const SizedBox.shrink();

    return AppImageCollage(
      imageUrls: item.photos,
      heroTagPrefix: 'info_feed_${item.id}',
      onImageTap: (initialIndex) {
        AppImageViewer.show(
          context,
          imageUrls: item.photos,
          initialIndex: initialIndex,
          heroTagPrefix: 'info_feed_${item.id}',
        );
      },
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    if (isSelectionMode) {
      if (!isSelectable) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: AppRadius.borderMedium,
          ),
          child: Center(
            child: AppSvgIcon(
              KawaloVectors.squareLock01,
              size: 24,
              color: colorScheme.outline,
            ),
          ),
        );
      }

      return AppSelectionLeading(
        selected: isSelected,
        selectedChild: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: AppRadius.borderMedium,
          ),
          child: Center(
            child: AppSvgIcon(
              KawaloVectors.check,
              color: colorScheme.onPrimary,
              size: 24,
            ),
          ),
        ),
        child: _buildAvatarImage(context),
      );
    }

    return _buildAvatarImage(context);
  }

  Widget _buildAvatarImage(BuildContext context) {
    final pic = item.userProfilePic;
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
