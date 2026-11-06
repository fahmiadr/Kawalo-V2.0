import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';

/// App bar khusus untuk layar detail tamu yang mengimplementasikan
/// [AppHomeAppBar] dengan tombol kembali, tier status pembaruan waktu,
/// dan tombol aksi check-out tamu di sisi kanan.
class GuestDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Membuat instance [GuestDetailAppBar].
  const GuestDetailAppBar({
    required this.greeting,
    this.title = 'Detail tamu',
    this.showBackButton = true,
    this.onBackPressed,
    this.onCheckout,
    this.isCheckingOut = false,
    this.enabled = true,
    this.trailing,
    super.key,
  });

  /// Status pembaruan waktu atau greeting di tier atas.
  final String greeting;

  /// Judul halaman pada tier kedua.
  final String title;

  /// Menentukan apakah tombol kembali ditampilkan.
  final bool showBackButton;

  /// Callback saat tombol navigasi kembali ditekan.
  final VoidCallback? onBackPressed;

  /// Callback saat tombol check-out tamu ditekan.
  final VoidCallback? onCheckout;

  /// Menandakan apakah proses check-out sedang berlangsung.
  final bool isCheckingOut;

  /// Menandakan apakah tombol check-out dapat diinteraksi.
  final bool enabled;

  /// Widget trailing kustom opsional jika ingin menggantikan tombol default.
  final Widget? trailing;

  @override
  Size get preferredSize =>
      const Size.fromHeight(AppHomeAppBar.defaultPreferredHeight);

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;

    var effectiveTrailing = trailing;
    double? effectiveTrailingWidth;

    if (effectiveTrailing == null && onCheckout != null) {
      effectiveTrailingWidth = 96;
      final isInteractive = enabled && !isCheckingOut;
      final backgroundColor =
          WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(
            alpha: AppStateLayer.disabledContainerOpacity,
          );
        }
        return colorScheme.secondaryContainer;
      });

      final foregroundColor =
          WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(
            alpha: AppStateLayer.disabledOpacity,
          );
        }
        return colorScheme.onSecondaryContainer;
      });

      effectiveTrailing = ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppStateLayer.minTouchTarget,
          minWidth: AppStateLayer.minTouchTarget,
        ),
        child: AppButton(
          enabled: isInteractive,
          semanticLabel: 'Check-out tamu',
          decoration: AppButtonDecoration(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
          ),
          onPressed: isInteractive ? onCheckout : null,
          child: Text(
            'Check-out',
            style: typeScale.labelLarge,
          ),
        ),
      );
    }

    final hasTrailing = effectiveTrailing != null;

    return AppHomeAppBar(
      greeting: greeting,
      title: title,
      showBackButton: showBackButton,
      onBackPressed: onBackPressed,
      showTrailing: hasTrailing,
      trailing: effectiveTrailing,
      trailingWidth: effectiveTrailingWidth,
    );
  }
}
