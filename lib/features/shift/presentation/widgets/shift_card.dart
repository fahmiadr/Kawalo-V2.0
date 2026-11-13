import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/shift/domain/entities/shift_entity.dart';
import 'package:kawalo_mobile/features/shift/presentation/extensions/shift_ui_extension.dart';
import 'package:kawalo_mobile/features/shift/presentation/shift_palette.dart';

/// One shift in the list. [onTap] is null for members who cannot edit.
class ShiftCard extends StatelessWidget {
  const ShiftCard({required this.shift, this.onTap, super.key});

  final ShiftEntity shift;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = shift.accentColor ?? colorScheme.primaryContainer;
    final onAccent = shift.accentColor == null
        ? colorScheme.onPrimaryContainer
        : onShiftColor(accent);

    return AppCard(
      onPressed: onTap,
      semanticLabel:
          '${shift.name}, ${shift.displaySchedule}'
          '${shift.endsNextDay ? ', berakhir besok' : ''}',
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space150,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  key: const ValueKey('shift_color_tile'),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconTheme(
                    data: IconThemeData(color: onAccent),
                    child: const AppSvgIcon(KawaloVectors.clockHour5, size: 22),
                  ),
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  shift.name,
                  style: theme.typography.emphasized.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null)
                AppSvgIcon(
                  KawaloVectors.arrowRight01,
                  size: 24,
                  color: colorScheme.onSurfaceVariant,
                ),
            ],
          ),
          AppSpacing.vGapSm,
          const AppDivider(),
          AppSpacing.vGapSm,
          _DetailRow(
            iconPath: KawaloColorVectors.timeRotation,
            text: shift.displaySchedule,
            tag: shift.endsNextDay
                ? const AppTag(
                    label: 'Berakhir besok',
                    variant: AppTagVariant.secondary,
                    size: AppTagSize.small,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.iconPath, required this.text, this.tag});

  final String iconPath;
  final String text;
  final Widget? tag;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Row(
      children: [
        AppSvgIcon.color(iconPath, size: 20),
        AppSpacing.hGapSm,
        Expanded(
          child: Text(
            text,
            style: theme.typeScale.labelMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (tag != null) ...[AppSpacing.hGapSm, tag!],
      ],
    );
  }
}
