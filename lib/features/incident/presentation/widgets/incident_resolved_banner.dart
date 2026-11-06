import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/presentation/extensions/incident_ui_extension.dart';

/// Banner status read-only yang ditampilkan menggantikan composer bar saat
/// insiden telah diselesaikan.
///
/// Menggunakan token Material 3 Expressive, transisi pegas
/// [AppMotion.spatialFast], dan ikon vektor Kawalo standar.
class IncidentResolvedBanner extends StatelessWidget {
  /// Membuat instance [IncidentResolvedBanner].
  const IncidentResolvedBanner({
    required this.incident,
    super.key,
  });

  /// Entitas insiden yang telah diselesaikan.
  final IncidentEntity incident;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedScale = theme.typography.emphasized;

    final resolverName = incident.displayResolver;
    final resolvedAt = incident.resolvedAt != null
        ? AppDateFormat.formatDate(incident.resolvedAt!)
        : 'Selesai';

    return AnimatedContainer(
      duration: AppMotion.isReducedMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space150,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: AppRadius.borderMedium,
              ),
              child: Center(
                child: AppSvgIcon(
                  KawaloVectors.squareLock01,
                  size: 20,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Diselesaikan oleh $resolverName • $resolvedAt',
                    style: emphasizedScale.titleSmall.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  AppSpacing.vGap25,
                  Text(
                    'Diskusi ditutup dan thread beralih ke mode baca saja.',
                    style: typeScale.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
