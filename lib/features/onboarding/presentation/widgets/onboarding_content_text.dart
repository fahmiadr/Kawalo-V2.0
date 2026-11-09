import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';

/// Text section widget displaying Title and Description for Onboarding.
class OnboardingContentText extends StatelessWidget {
  const OnboardingContentText({
    required this.title,
    required this.description,
    super.key,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: emphasizedTypeScale.headlineSmall.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        AppSpacing.gap200,
        Text(
          description,
          textAlign: TextAlign.center,
          style: typeScale.bodyLarge.copyWith(color: colorScheme.onSurface),
        ),
      ],
    );
  }
}
