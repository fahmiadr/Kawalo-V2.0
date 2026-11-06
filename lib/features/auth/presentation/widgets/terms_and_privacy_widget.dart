import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';

/// Terms of Service and Privacy Policy consent text widget formatted as a
/// continuous inline text paragraph with accessible hyperlinks.
class TermsAndPrivacyWidget extends StatelessWidget {
  const TermsAndPrivacyWidget({
    this.onPrivacyTap,
    this.onTermsTap,
    super.key,
  });

  final VoidCallback? onPrivacyTap;
  final VoidCallback? onTermsTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;

    final defaultStyle = typeScale.labelLarge.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    final linkStyle = emphasizedTypeScale.bodyMedium.copyWith(
      color: colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: colorScheme.primary,
      decorationThickness: 1.2,
    );

    return Padding(
      padding: AppSpacing.paddingHorizontalXs,
      child: Semantics(
        container: true,
        child: Text.rich(
          TextSpan(
            style: defaultStyle,
            children: [
              const TextSpan(text: 'Dengan masuk, Anda menyetujui '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: AppTappable(
                  onTap: onPrivacyTap,
                  semanticLabel: 'Kebijakan Privasi',
                  child: Text(
                    'Kebijakan Privasi',
                    style: linkStyle,
                  ),
                ),
              ),
              const TextSpan(text: ' dan '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: AppTappable(
                  onTap: onTermsTap,
                  semanticLabel: 'Ketentuan Layanan',
                  child: Text(
                    'Ketentuan Layanan',
                    style: linkStyle,
                  ),
                ),
              ),
              const TextSpan(text: ' Kawalo.'),
            ],
          ),
          textAlign: TextAlign.center,
          style: defaultStyle,
        ),
      ),
    );
  }
}
