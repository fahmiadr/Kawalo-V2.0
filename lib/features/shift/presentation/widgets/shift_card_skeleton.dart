import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';

class ShiftCardSkeleton extends StatelessWidget {
  const ShiftCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.of(context).colorScheme.surfaceContainerHigh;

    Widget bar(double width, double height, BorderRadius radius) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: radius),
    );

    return ExcludeSemantics(
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space200,
          vertical: AppSpacing.space150,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                bar(40, 40, AppRadius.borderMedium),
                AppSpacing.hGapSm,
                bar(140, 16, AppRadius.borderSmall),
              ],
            ),
            AppSpacing.vGap150,
            bar(180, 12, AppRadius.borderSmall),
            AppSpacing.vGapSm,
            bar(220, 12, AppRadius.borderSmall),
          ],
        ),
      ),
    );
  }
}
