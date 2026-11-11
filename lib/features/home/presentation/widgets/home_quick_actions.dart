import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

/// Komponen aksi cepat utama ("Absensi").
///
/// Menggunakan [AppButton] bertipe [AppButtonColor.elevated] dengan
/// bentuk stadium/pill dan ukuran proporsional sesuai desain Figma.
class HomeQuickActions extends StatelessWidget {
  /// Membuat instance [HomeQuickActions].
  const HomeQuickActions({super.key, this.onAbsensiPressed});

  /// Callback saat tombol "Absensi" ditekan.
  final VoidCallback? onAbsensiPressed;

  void _defaultOnAbsensi(BuildContext context) {
    AppSnackbar.show(context, message: 'Membuka pemindai Absensi...');
  }

  @override
  Widget build(BuildContext context) {
    return _QuickActionButton(
      iconPath: KawaloColorVectors.phoneLocation1,
      label: 'Absensi',
      semanticLabel: 'Absensi',
      onPressed: onAbsensiPressed ?? () => _defaultOnAbsensi(context),
    );
  }
}

/// Tombol individual aksi cepat menggunakan [AppButton] elevated.
class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.iconPath,
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String iconPath;
  final String label;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final emphasizedTypeScale = AppTheme.emphasizedTypeScaleOf(context);

    return Semantics(
      button: true,
      label: semanticLabel,
      child: AppButton(
        style: AppButtonColor.elevated,
        size: AppButtonSize.custom(height: 72, hPadding: AppSpacing.space200),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon.color(iconPath, size: 40),
            AppSpacing.hGapSm,
            Flexible(
              child: Text(
                label,
                style: emphasizedTypeScale.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
