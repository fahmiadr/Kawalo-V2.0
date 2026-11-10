import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';

class ScheduleCardSkeleton extends StatelessWidget {
  const ScheduleCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.of(context).colorScheme.surfaceContainerHigh;

    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.borderSmall,
      ),
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
            bar(140, 16),
            AppSpacing.vGapSm,
            bar(110, 12),
            AppSpacing.vGap50,
            bar(90, 12),
          ],
        ),
      ),
    );
  }
}
