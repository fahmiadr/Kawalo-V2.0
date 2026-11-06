import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/presentation/extensions/guest_ui_extension.dart';

/// Kartu informasi kunjungan dan penanggung jawab pada layar detail tamu.
///
/// Memuat 3 sub-seksi:
/// 1. Detail kunjungan (tujuan & destinasi/lokasi).
/// 2. Bertemu dengan (nama & email host).
/// 3. Petugas pencatat dan verifikasi (petugas check-in & check-out).
class GuestDetailVisitInfoCard extends StatelessWidget {
  /// Membuat instance [GuestDetailVisitInfoCard].
  const GuestDetailVisitInfoCard({
    required this.item,
    super.key,
  });

  /// Data tamu yang ditampilkan.
  final GuestItemEntity item;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedScale = theme.typography.emphasized;

    final semanticLabel = 'Informasi kunjungan dan penanggung jawab, '
        'tujuan ${item.displayPurpose}, '
        'destinasi ${item.displayDestination}, bertemu dengan '
        '${item.displayGuestToUserName}, '
        'dicatat oleh ${item.displayRecordedBy}';

    final hasCheckout = item.hasCheckout;

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
          // ── Sub-seksi: Detail Kunjungan ─────────────────────────────────
          Row(
            children: [
              const AppSvgIcon.color(
                KawaloColorVectors.log1,
                size: 32,
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  'Detail kunjungan',
                  style: emphasizedScale.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGap200,
          Text(
            'Tujuan',
            style: typeScale.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGap25,
          Text(
            item.displayPurpose,
            style: emphasizedScale.bodyLarge.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          AppSpacing.vGapSm,
          Text(
            'Destinasi',
            style: typeScale.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGap25,
          Text(
            item.displayDestination,
            style: emphasizedScale.bodyLarge.copyWith(
              color: colorScheme.onSurface,
            ),
          ),

          // ── Pemisah ─────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.space150),
            child: AppDivider(),
          ),

          // ── Sub-seksi: Bertemu Dengan ───────────────────────────────────
          Row(
            children: [
              const AppSvgIcon.color(
                KawaloColorVectors.patrol3,
                size: 32,
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  'Bertemu dengan',
                  style: emphasizedScale.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGap200,
          Text(
            item.displayGuestToUserName,
            style: emphasizedScale.bodyLarge.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          AppSpacing.vGap25,
          Text(
            item.displayGuestToUserEmail,
            style: typeScale.labelMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          // ── Pemisah ─────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.space150),
            child: AppDivider(),
          ),

          // ── Sub-seksi: Petugas Pencatat & Verifikasi ─────────────────────
          Row(
            children: [
              const AppSvgIcon.color(
                KawaloColorVectors.checklist5,
                size: 32,
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  'Petugas pencatat dan verifikasi',
                  style: emphasizedScale.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGap200,
          Text(
            'Dicatat oleh',
            style: typeScale.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGap25,
          Text(
            item.displayRecordedBy,
            style: emphasizedScale.bodyLarge.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          AppSpacing.vGap25,
          Text(
            item.displayRecorderEmail,
            style: typeScale.labelMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (hasCheckout) ...[
            AppSpacing.vGapSm,
            Text(
              'Checkout oleh',
              style: typeScale.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.vGap25,
            Text(
              item.displayCheckoutByName != '-'
                  ? item.displayCheckoutByName
                  : item.displayCheckoutByEmail,
              style: emphasizedScale.bodyLarge.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            if (item.displayCheckoutByName != '-' &&
                item.displayCheckoutByEmail != '-') ...[
              AppSpacing.vGap25,
              Text(
                item.displayCheckoutByEmail,
                style: typeScale.labelMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
