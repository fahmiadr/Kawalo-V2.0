import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';

class SubtitleWidget extends StatelessWidget {
  const SubtitleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final emphasizedTypeScale = theme.typography.emphasized;

    return Text(
      'Keamanan Terpadu. Efisiensi Maksimal.',
      textAlign: TextAlign.center,
      style: emphasizedTypeScale.bodyMedium.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
