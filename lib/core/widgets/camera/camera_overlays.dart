import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';

/// Indikator pemuatan viewport kamera dengan tema terang (Light Theme)
/// Material 3 Expressive dan label semantik aksesibilitas.
class CameraLoadingIndicator extends StatelessWidget {
  const CameraLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: M3ETheme(
        data: AppTheme.m3eDark(),
        child: Theme(
          data: AppTheme.darkThemeData(),
          child: const AppLoadingIndicator(semanticLabel: 'Menyiapkan kamera'),
        ),
      ),
    );
  }
}

/// Atom efek visual kilatan tirai rana kamera Material 3 Expressive.
class CameraShutterFlash extends StatelessWidget {
  const CameraShutterFlash({
    required this.animation,
    required this.colorScheme,
    super.key,
  });

  final Animation<double> animation;
  final M3EColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.isReducedMotion(context)) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final progress = animation.value;
          if (progress <= 0 || progress >= 1.0) {
            return const SizedBox.shrink();
          }

          // Tirai menutup dalam 30% awal durasi, lalu memudar kembali ke 0.0
          final double opacity;
          if (progress < 0.30) {
            opacity = (progress / 0.30) * 0.90;
          } else {
            opacity = (1.0 - ((progress - 0.30) / 0.70)) * 0.90;
          }

          return Container(
            color: colorScheme.scrim.withValues(alpha: opacity.clamp(0.0, 1.0)),
          );
        },
      ),
    );
  }
}

/// Atom overlay bingkai cahaya translusen kamera depan (Illuminated Frame).
class IlluminatedFrameOverlay extends StatelessWidget {
  const IlluminatedFrameOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        // Jendela tengah 72% dari dimensi kontainer
        final cutoutWidth = size.width * 0.72;
        final cutoutHeight = size.height * 0.72;
        final cutoutLeft = (size.width - cutoutWidth) / 2;
        final cutoutTop = (size.height - cutoutHeight) / 2;

        final cutoutRect = Rect.fromLTWH(
          cutoutLeft,
          cutoutTop,
          cutoutWidth,
          cutoutHeight,
        );

        return CustomPaint(
          size: size,
          painter: _IlluminatedFramePainter(
            cutoutRect: cutoutRect,
            borderRadius: AppRadius.borderExtraLarge,
            frameColor: Colors.white.withValues(alpha: 0.70),
            borderColor: Colors.white,
            borderWidth: 2,
          ),
        );
      },
    );
  }
}

class _IlluminatedFramePainter extends CustomPainter {
  const _IlluminatedFramePainter({
    required this.cutoutRect,
    required this.borderRadius,
    required this.frameColor,
    required this.borderColor,
    required this.borderWidth,
  });

  final Rect cutoutRect;
  final BorderRadius borderRadius;
  final Color frameColor;
  final Color borderColor;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final fullPath = Path()..addRect(Offset.zero & size);
    final cutoutRRect = borderRadius.toRRect(cutoutRect);
    final cutoutPath = Path()..addRRect(cutoutRRect);

    // 1. Bingkai cahaya translusen luar (Difference path)
    final framePath = Path.combine(
      PathOperation.difference,
      fullPath,
      cutoutPath,
    );
    final framePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(framePath, framePaint);

    // 2. Garis tepi penegas jendela tengah
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRRect(cutoutRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _IlluminatedFramePainter oldDelegate) {
    return oldDelegate.cutoutRect != cutoutRect ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.frameColor != frameColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}
