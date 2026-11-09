import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

/// Kartu input tanggal (label + tanggal terpilih) pada tampilan rentang kustom.
class DateFilterDateCard extends StatelessWidget {
  const DateFilterDateCard({
    required this.label,
    required this.date,
    required this.onTap,
    super.key,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final date = this.date;
    final hasValue = date != null;
    final displayText = hasValue
        ? AppDateFormat.formatDateOnly(date)
        : 'Pilih tanggal';

    return AppCard(
      variant: AppCardVariant.filled,
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space150,
      ),
      semanticLabel: '$label: $displayText',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: typeScale.bodyLarge.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                AppSpacing.vGapXs,
                Text(
                  displayText,
                  style: typeScale.bodyLarge.copyWith(
                    color: hasValue
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppSvgIcon(
            KawaloVectors.calendar05,
            size: 24,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
