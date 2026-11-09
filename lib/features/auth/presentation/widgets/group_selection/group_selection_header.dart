import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';

class GroupSelectionHeader extends StatelessWidget {
  const GroupSelectionHeader({required this.userName, super.key});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;
    final typeScale = AppTheme.typeScaleOf(context);
    final emphasizedScale = AppTheme.emphasizedTypeScaleOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pilih grup',
          style: emphasizedScale.headlineMedium.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        AppSpacing.vGapXs,
        Text(
          'Halo, $userName! Akun Anda '
          'terdaftar di beberapa grup '
          'organisasi. Pilih grup aktif untuk '
          'memulai operasional.',
          style: typeScale.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
