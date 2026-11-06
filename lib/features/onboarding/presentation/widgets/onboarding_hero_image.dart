import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/widgets/app_image_placeholder.dart';

/// Hero image / illustration widget for Onboarding screen using local assets.
class OnboardingHeroImage extends StatelessWidget {
  const OnboardingHeroImage({
    super.key,
    this.imagePath = 'assets/illustrations/onboarding_welcome.png',
    this.height,
  });

  final String imagePath;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final imageWidget = Image.asset(
      imagePath,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) {
        return const AppImagePlaceholder(
          label: 'Illustration',
          iconSize: 48,
        );
      },
    );

    if (height != null) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: imageWidget,
      );
    }

    return SizedBox(
      width: double.infinity,
      child: imageWidget,
    );
  }
}
