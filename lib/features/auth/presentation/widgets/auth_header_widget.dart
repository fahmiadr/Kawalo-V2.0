import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_image_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

/// Header widget displaying app logo, "Selamat Datang" title, and description.
class AuthHeaderWidget extends StatelessWidget {
  const AuthHeaderWidget({
    this.title = 'Selamat Datang',
    this.subtitle = 'Silakan masukkan kredensial Anda untuk melanjutkan.',
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final logoSize = screenWidth >= AppLayout.compactBreakpoint ? 120.0 : 96.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // App Logo dengan ukuran responsif (96px di HP, 120px di Tablet/Layar Lebar)
        Semantics(
          label: 'Logo Kawalo',
          child: SizedBox(
            width: logoSize,
            height: logoSize,
            child: SvgPicture.asset(
              'assets/logos/logo.svg',
              width: logoSize,
              height: logoSize,
              placeholderBuilder: (context) {
                return AppImagePlaceholder(
                  label: 'Logo',
                  icon: AppSvgIcon(
                    KawaloVectors.shield01,
                    size: logoSize * 0.42,
                    color: colorScheme.secondary,
                  ),
                  iconSize: logoSize * 0.42,
                  borderRadius: BorderRadius.circular(logoSize / 2),
                );
              },
            ),
          ),
        ),

        AppSpacing.vGap200,

        // Header Title
        Text(
          title,
          textAlign: TextAlign.center,
          style: emphasizedTypeScale.headlineMedium.copyWith(
            color: colorScheme.onSurface,
          ),
        ),

        AppSpacing.vGapSm,

        // Subtitle Description
        Padding(
          padding: AppSpacing.paddingHorizontal200,
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: typeScale.bodyLarge.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
