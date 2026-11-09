import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';

/// Ambient glowing background blur effect for Splash Screen.
class BackgroundGlowWidget extends StatelessWidget {
  const BackgroundGlowWidget({super.key, this.size, this.color});

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.colorSchemeOf(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final effectiveSize =
        size ?? (screenWidth >= AppLayout.compactBreakpoint ? 400.0 : 300.0);
    final effectiveColor =
        color ?? colorScheme.inversePrimary.withValues(alpha: 0.32);

    return ExcludeSemantics(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: 170,
          sigmaY: 170,
          tileMode: TileMode.decal,
        ),
        child: Container(
          width: effectiveSize,
          height: effectiveSize,
          decoration: BoxDecoration(
            color: effectiveColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
