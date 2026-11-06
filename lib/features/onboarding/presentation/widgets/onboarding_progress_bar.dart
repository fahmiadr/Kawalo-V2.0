import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';

/// Progress bar indicator with left-to-right fill animation for onboarding.
class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({
    super.key,
    this.totalSteps = 5,
    this.currentStep = 0,
    this.stepProgress = 0.0,
  });

  final int totalSteps;
  final int currentStep;
  final double stepProgress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.colorSchemeOf(context);

    return Semantics(
      liveRegion: true,
      label: 'Langkah ${currentStep + 1} dari $totalSteps',
      child: Row(
        children: List.generate(totalSteps, (index) {
          var factor = 0.0;
          if (index < currentStep) {
            factor = 1.0;
          } else if (index == currentStep) {
            factor = stepProgress.clamp(0.0, 1.0);
          } else {
            factor = 0.0;
          }

          return Expanded(
            child: Container(
              height: AppSpacing.space50,
              margin: EdgeInsetsDirectional.only(
                end: index == totalSteps - 1 ? 0 : AppSpacing.space50,
              ),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: AppRadius.borderFull,
              ),
              clipBehavior: Clip.antiAlias,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: factor,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.secondary,
                      borderRadius: AppRadius.borderFull,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
