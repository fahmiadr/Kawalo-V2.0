import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';

// ============================================================================
// MOLECULE: Center Precision Pin Marker (M3 Expressive Custom Shape & Lift)
// ============================================================================

/// Painter kustom untuk bayangan elips dinamis di lantai di bawah target dot.
class _GroundShadowPainter extends CustomPainter {
  const _GroundShadowPainter({
    required this.shadowColor,
    required this.liftProgress,
  });

  final Color shadowColor;
  final double liftProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Saat terangkat (liftProgress -> 1.0), bayangan memudar dan melembut.
    final radiusX = 6.0 - (1.5 * liftProgress);
    final radiusY = 2.5 - (0.5 * liftProgress);
    final opacity = (0.28 - (0.16 * liftProgress)).clamp(0.05, 0.35);

    final paint = Paint()
      ..color = shadowColor.withValues(alpha: opacity)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        2.0 + (2.0 * liftProgress),
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radiusX * 2,
        height: radiusY * 2,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GroundShadowPainter oldDelegate) {
    return oldDelegate.shadowColor != shadowColor ||
        oldDelegate.liftProgress != liftProgress;
  }
}

/// Painter kustom untuk siluet pin lokasi Material 3 Expressive.
///
/// Menggambar pin geometris dengan kepala lingkaran di bagian atas, kurva
/// kubik presisi menyambung ke ujung runcingan di bawah, border kontras
/// permukaan, lingkaran dalam (inner core), dan bayangan elevasi dinamis.
class _MapPinPainter extends CustomPainter {
  const _MapPinPainter({
    required this.pinColor,
    required this.strokeColor,
    required this.shadowColor,
    this.elevation = 3,
  });

  final Color pinColor;
  final Color strokeColor;
  final Color shadowColor;
  final double elevation;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final scaleX = w / 32;
    final scaleY = h / 42;

    canvas
      ..save()
      ..scale(scaleX, scaleY);

    final path = Path()
      // Mulai dari ujung jarum bawah
      ..moveTo(16, 42)
      // Kurva sisi kiri mengalir mulus ke tepi kiri lingkaran kepala
      ..cubicTo(13.5, 34, 0, 26, 0, 16)
      // Busur setengah lingkaran atas beradius 16dp
      ..arcToPoint(
        const Offset(32, 16),
        radius: const Radius.circular(16),
      )
      // Kurva sisi kanan simetris kembali ke ujung jarum
      ..cubicTo(32, 26, 18.5, 34, 16, 42)
      ..close();

    // 1. Gambar bayangan elevasi pin
    if (elevation > 0) {
      canvas.drawShadow(path, shadowColor, elevation, false);
    }

    // 2. Gambar badan pin (fill)
    final fillPaint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 3. Gambar stroke kontras luar (1.5dp)
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    // 4. Gambar lingkaran dalam (inner core) di pusat lingkaran atas (16, 16)
    final innerPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;
    canvas
      ..drawCircle(const Offset(16, 16), 5, innerPaint)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _MapPinPainter oldDelegate) {
    return oldDelegate.pinColor != pinColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.elevation != elevation;
  }
}

/// Penanda titik tengah interaktif dengan ground target dot presisi
/// dan custom shape pin Material 3 Expressive yang terangkat saat peta
/// digeser.
class MapCenterPinMarker extends StatefulWidget {
  const MapCenterPinMarker({
    required this.isMovingListenable,
    super.key,
  });

  final ValueListenable<bool> isMovingListenable;

  @override
  State<MapCenterPinMarker> createState() => _MapCenterPinMarkerState();
}

class _MapCenterPinMarkerState extends State<MapCenterPinMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late Animation<double> _liftAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 280),
    );

    _liftAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutBack,
    );

    widget.isMovingListenable.addListener(_handleMovingChange);
    if (widget.isMovingListenable.value) {
      _animController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant MapCenterPinMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isMovingListenable != widget.isMovingListenable) {
      oldWidget.isMovingListenable.removeListener(_handleMovingChange);
      widget.isMovingListenable.addListener(_handleMovingChange);
    }
  }

  @override
  void dispose() {
    widget.isMovingListenable.removeListener(_handleMovingChange);
    _animController.dispose();
    super.dispose();
  }

  void _handleMovingChange() {
    if (!mounted) return;
    final isReduced = AppMotion.isReducedMotion(context);
    if (widget.isMovingListenable.value) {
      if (isReduced) {
        _animController.value = 1.0;
      } else {
        _animController.forward();
      }
    } else {
      if (isReduced) {
        _animController.value = 0.0;
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;

    return IgnorePointer(
      child: Center(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _liftAnimation,
            builder: (context, _) {
              final progress = _liftAnimation.value;
              // Saat idle: progress = 0.0 -> Y = -21 (ujung jarum di 0, 0)
              // Saat moving: progress = 1.0 -> Y = -29 (terangkat 8dp)
              final translateY = -21 - (8 * progress);
              final scale = 1 + (0.04 * progress);
              final elevation = 3 + (3 * progress);

              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // 1. Bayangan elips di lantai
                  CustomPaint(
                    size: const Size(24, 12),
                    painter: _GroundShadowPainter(
                      shadowColor: colorScheme.shadow,
                      liftProgress: progress,
                    ),
                  ),

                  // 2. Ground target dot permanen terkunci di pusat (0, 0)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.surface,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),

                  // 3. Badan Pin Kustom M3 Expressive terangkat saat bergerak
                  Transform.translate(
                    offset: Offset(0, translateY),
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.bottomCenter,
                      child: CustomPaint(
                        size: const Size(32, 42),
                        painter: _MapPinPainter(
                          pinColor: colorScheme.primary,
                          strokeColor: colorScheme.surface,
                          shadowColor: colorScheme.shadow,
                          elevation: elevation,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
