import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

/// Atom indikator kuota foto kamera multi-shot.
class CameraQuotaBadge extends StatelessWidget {
  const CameraQuotaBadge({
    required this.totalPhotos,
    required this.maxPhotos,
    required this.colorScheme,
    required this.emphasizedTypeScale,
    super.key,
  });

  final int totalPhotos;
  final int maxPhotos;
  final M3EColorScheme colorScheme;
  final M3ETypeScale emphasizedTypeScale;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$totalPhotos dari $maxPhotos foto dipilih',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space150,
          vertical: AppSpacing.space50,
        ),
        decoration: BoxDecoration(
          color: colorScheme.scrim.withValues(alpha: 0.60),
          borderRadius: AppRadius.borderFull,
          border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppSvgIcon(
              KawaloVectors.camera01,
              size: 16,
              color: Colors.white,
            ),
            AppSpacing.hGap100,
            Text(
              '$totalPhotos / $maxPhotos foto',
              style: emphasizedTypeScale.labelLarge.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
