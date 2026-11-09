import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_radio.dart';
import 'package:kawalo_mobile/core/widgets/app_selection_tile.dart';
import 'package:kawalo_mobile/core/widgets/date_filter/app_date_filter_models.dart';

/// Tampilan opsi filter utama (Hari ini, Pekan ini, dsb) pada
/// `AppDateFilterBottomSheet`.
class DateFilterOptionsView extends StatelessWidget {
  const DateFilterOptionsView({
    required this.title,
    required this.dateRangeTitle,
    required this.enableDateRange,
    required this.selectedPeriod,
    required this.hasCustomFilters,
    required this.additionalSections,
    required this.resolvePeriodDateRange,
    required this.onPeriodSelected,
    required this.onReset,
    required this.onApply,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String dateRangeTitle;
  final bool enableDateRange;
  final AppDateFilterPeriod selectedPeriod;
  final bool hasCustomFilters;
  final List<Widget> additionalSections;
  final String? Function(AppDateFilterPeriod period) resolvePeriodDateRange;
  final ValueChanged<AppDateFilterPeriod> onPeriodSelected;
  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final isDefault =
        selectedPeriod == AppDateFilterPeriod.today && !hasCustomFilters;

    return AppFilterBottomSheet(
      key: const ValueKey('filter_options_view'),
      isRoot: false,
      title: title,
      subtitle: enableDateRange ? (subtitle ?? dateRangeTitle) : null,
      isResetEnabled: !isDefault,
      onReset: onReset,
      resetSemanticLabel: isDefault
          ? 'Filter dalam kondisi default'
          : 'Kembalikan filter ke Hari ini',
      applySemanticLabel: 'Terapkan filter tanggal',
      onApply: onApply,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (enableDateRange) ...[
            ...AppDateFilterPeriod.values.map((period) {
              final isSelected = selectedPeriod == period;
              final dateRangeText = isSelected
                  ? resolvePeriodDateRange(period)
                  : null;
              final periodSemanticLabel = dateRangeText != null
                  ? 'Pilih ${period.label}, $dateRangeText'
                  : 'Pilih ${period.label}';

              return AppSelectionTile(
                title: period.label,
                subtitleWidget: dateRangeText != null
                    ? Text(
                        dateRangeText,
                        style: typeScale.bodyMedium.copyWith(
                          color: colorScheme.primary,
                        ),
                      )
                    : null,
                selected: isSelected,
                semanticLabel: periodSemanticLabel,
                trailing: AppRadio<AppDateFilterPeriod>(
                  value: period,
                  groupValue: selectedPeriod,
                  onChanged: onPeriodSelected,
                ),
                onTap: () => onPeriodSelected(period),
              );
            }),
          ],
          if (additionalSections.isNotEmpty) ...[
            if (enableDateRange)
              const Padding(
                padding: AppSpacing.paddingVertical150,
                child: AppDivider(),
              ),
            for (var i = 0; i < additionalSections.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: AppSpacing.paddingVertical150,
                  child: AppDivider(),
                ),
              additionalSections[i],
            ],
          ],
        ],
      ),
    );
  }
}
