import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';

/// Tombol app bar untuk menandai insiden selesai.
class IncidentDetailResolveButton extends StatelessWidget {
  /// Membuat instance [IncidentDetailResolveButton].
  const IncidentDetailResolveButton({
    required this.isResolving,
    required this.isOffline,
    required this.onPressed,
    super.key,
  });

  /// Apakah proses resolusi sedang berjalan.
  final bool isResolving;

  /// Apakah perangkat sedang offline.
  final bool isOffline;

  /// Dipanggil saat tombol ditekan (hanya bila aktif).
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final typeScale = AppTheme.of(context).typeScale;

    return AppButton(
      enabled: !isResolving && !isOffline,
      semanticLabel: 'Selesaikan insiden',
      onPressed: isResolving || isOffline ? null : onPressed,
      child: isResolving
          ? const SizedBox(width: 16, height: 16, child: AppLoadingIndicator())
          : Text('Selesaikan', style: typeScale.labelLarge),
    );
  }
}
