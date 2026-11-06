import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/presentation/extensions/operational_item_ui_extension.dart';

/// Kartu profil dan status kedinasan personil operasional pada layar detail.
///
/// Menampilkan foto/avatar personil (mendukung foto dari `UserProfilePic`
/// dengan fallback ke vektor `patrol2`), nama, email, serta tag status dinas
/// makro (`ON DUTY` / `OFF DUTY`).
class OperationalDetailProfileCard extends StatelessWidget {
  /// Membuat instance [OperationalDetailProfileCard].
  const OperationalDetailProfileCard({
    required this.item,
    super.key,
  });

  /// Data personil operasional yang ditampilkan.
  final OperationalItemEntity item;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;

    final semanticLabel =
        'Profil personil operasional ${item.displayUserName}, '
        'email ${item.displayUserEmail}, '
        'status dinas ${item.displayLatestDuty}';

    return AppCard(
      semanticLabel: semanticLabel,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space150,
      ),
      child: Row(
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
                  item.displayUserName,
                  style: emphasizedTypeScale.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                AppSpacing.vGap25,
                Text(
                  item.displayUserEmail,
                  style: typeScale.labelMedium.copyWith(
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
                      label: item.displayLatestDuty,
                      variant: item.displayDutyTagVariant,
                      size: AppTagSize.small,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final pic = item.userProfilePic?.trim();
    final isNetworkUrl = pic != null &&
        (pic.startsWith('http://') || pic.startsWith('https://'));

    if (isNetworkUrl) {
      return ClipRRect(
        borderRadius: AppRadius.borderMedium,
        child: CachedNetworkImage(
          imageUrl: pic,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildAvatarFallback(),
          errorWidget: (_, __, ___) => _buildAvatarFallback(),
        ),
      );
    }

    return _buildAvatarFallback();
  }

  Widget _buildAvatarFallback() {
    return const ClipRRect(
      borderRadius: AppRadius.borderMedium,
      child: AppSvgIcon.color(
        KawaloColorVectors.patrol2,
        size: 64,
      ),
    );
  }
}
