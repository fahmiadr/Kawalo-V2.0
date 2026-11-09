import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';

/// Banner status rekoneksi realtime di atas konten detail insiden.
class IncidentDetailReconnectingBanner extends StatelessWidget {
  /// Membuat instance [IncidentDetailReconnectingBanner].
  const IncidentDetailReconnectingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;

    return Container(
      width: double.infinity,
      color: colorScheme.errorContainer.withValues(alpha: 0.9),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space75,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 14, height: 14, child: AppLoadingIndicator()),
          AppSpacing.hGapSm,
          Flexible(
            child: Text(
              'Menghubungkan kembali ke server...',
              style: typeScale.labelSmall.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
