import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

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

/// Tombol app bar untuk menghapus laporan insiden (khusus Administrator).
class IncidentDetailDeleteButton extends StatelessWidget {
  /// Membuat instance [IncidentDetailDeleteButton].
  const IncidentDetailDeleteButton({
    required this.isDeleting,
    required this.isOffline,
    required this.onPressed,
    super.key,
  });

  /// Apakah proses penghapusan sedang berjalan.
  final bool isDeleting;

  /// Apakah perangkat sedang offline.
  final bool isOffline;

  /// Dipanggil saat tombol ditekan (hanya bila aktif).
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;

    return AppIconButton(
      onPressed: isDeleting || isOffline ? null : onPressed,
      tooltip: 'Hapus insiden',
      semanticLabel: 'Hapus laporan insiden',
      icon: AppSvgIcon(
        KawaloVectors.delete01,
        size: 24,
        color: colorScheme.error,
      ),
    );
  }
}
