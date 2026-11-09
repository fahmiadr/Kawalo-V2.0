import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

/// Chrome atas `AppImageViewer`: pill penghitung indeks di tengah dan tombol
/// tutup di kanan, dengan animasi tampil/sembunyi.
class ImageViewerTopChrome extends StatelessWidget {
  const ImageViewerTopChrome({
    required this.opacity,
    required this.showChrome,
    required this.isDragging,
    required this.currentIndex,
    required this.total,
    required this.onClose,
    super.key,
  });

  final double opacity;
  final ValueListenable<bool> showChrome;
  final bool isDragging;
  final int currentIndex;
  final int total;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: ValueListenableBuilder<bool>(
        valueListenable: showChrome,
        builder: (context, showChrome, child) {
          return AnimatedSlide(
            duration: AppDuration.short4,
            curve: AppMotion.standard,
            offset: showChrome ? Offset.zero : const Offset(0, -1),
            child: AnimatedOpacity(
              duration: AppDuration.short4,
              curve: AppMotion.standard,
              opacity: showChrome ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !showChrome || isDragging,
                child: child,
              ),
            ),
          );
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space200,
              vertical: AppSpacing.space100,
            ),
            child: Row(
              children: [
                // Sisi Kiri Penyeimbang
                const SizedBox(width: AppStateLayer.minTouchTarget),

                // Tengah: Pill Counter Indeks
                Expanded(
                  child: Center(
                    child: ImageViewerIndexCounter(
                      currentIndex: currentIndex,
                      total: total,
                    ),
                  ),
                ),

                // Kanan Atas: Tombol Tutup
                ImageViewerCloseButton(onPressed: onClose),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill penghitung indeks gambar ("1 / 3").
class ImageViewerIndexCounter extends StatelessWidget {
  const ImageViewerIndexCounter({
    required this.currentIndex,
    required this.total,
    super.key,
  });

  final int currentIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final emphasizedTypeScale = theme.typography.emphasized;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space150,
        vertical: AppSpacing.space50,
      ),
      decoration: BoxDecoration(
        color: colorScheme.scrim.withValues(alpha: 0.60),
        borderRadius: AppRadius.borderFull,
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
      ),
      child: Text(
        '${currentIndex + 1} / $total',
        style: emphasizedTypeScale.labelLarge.copyWith(color: Colors.white),
      ),
    );
  }
}

/// Tombol tutup penampil gambar.
class ImageViewerCloseButton extends StatelessWidget {
  const ImageViewerCloseButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.colorSchemeOf(context);

    return AppIconButton(
      icon: const AppSvgIcon(KawaloVectors.cancel01, color: Colors.white),
      decoration: M3EIconButtonDecoration(
        backgroundColor: WidgetStatePropertyAll(
          colorScheme.scrim.withValues(alpha: 0.60),
        ),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        side: WidgetStatePropertyAll(
          BorderSide(color: Colors.white.withValues(alpha: 0.30)),
        ),
      ),
      tooltip: 'Tutup penampil gambar',
      semanticLabel: 'Tutup penampil gambar',
      onPressed: onPressed,
    );
  }
}
