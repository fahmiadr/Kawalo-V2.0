import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/widgets/kawalo_logo.dart';

/// Responsive brand typography logo for KAWALO Splash Screen.
class BrandLogoWidget extends StatelessWidget {
  const BrandLogoWidget({
    super.key,
    this.fontSize,
  });

  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final effectiveFontSize =
        fontSize ?? (screenWidth >= AppLayout.compactBreakpoint ? 76.0 : 60.0);

    return KawaloLogoText(
      fontSize: effectiveFontSize,
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      semanticLabel: 'KAWALO',
    );
  }
}
