import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/camera/camera_overlays.dart';

/// Molekul viewfinder kamera dengan gesture touch-to-focus
/// dan indikator reticle Material 3 Expressive.
class CameraViewfinder extends StatefulWidget {
  const CameraViewfinder({
    required this.controller,
    required this.colorScheme,
    required this.flashMode,
    this.hasPhysicalFlash = false,
    super.key,
  });

  final CameraController controller;
  final M3EColorScheme colorScheme;
  final FlashMode flashMode;
  final bool hasPhysicalFlash;

  @override
  State<CameraViewfinder> createState() => _CameraViewfinderState();
}

class _CameraViewfinderState extends State<CameraViewfinder>
    with TickerProviderStateMixin {
  Offset? _focusPosition;
  late final AnimationController _entryController;
  late final AnimationController _exitController;
  Timer? _hideTimer;
  Timer? _dismissTimer;
  bool _isAfAssistActive = false;
  bool _isFocusUnsupportedOnDevice = false;
  bool _isExposureUnsupportedOnDevice = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController.unbounded(
      vsync: this,
      duration: AppDuration.medium1,
    );
    _exitController = AnimationController(
      vsync: this,
      duration: AppDuration.short3,
    );
  }

  @override
  void didUpdateWidget(covariant CameraViewfinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _isFocusUnsupportedOnDevice = false;
      _isExposureUnsupportedOnDevice = false;
    }
    if (oldWidget.flashMode != widget.flashMode && _isAfAssistActive) {
      _deactivateAfAssist();
    }
  }

  @override
  void dispose() {
    _deactivateAfAssist();
    _hideTimer?.cancel();
    _dismissTimer?.cancel();
    _entryController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _deactivateAfAssist() async {
    if (_isAfAssistActive) {
      _isAfAssistActive = false;
      try {
        await widget.controller.setFlashMode(widget.flashMode);
      } on Object catch (_) {
        // Abaikan error hardware saat restorasi mode flash
      }
    }
  }

  Future<void> _handleTapDown(
    TapDownDetails details,
    BoxConstraints constraints,
  ) async {
    final local = details.localPosition;
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;

    if (width <= 0 || height <= 0) return;

    final controller = widget.controller;
    if (!controller.value.isInitialized) return;

    // Periksa kapabilitas hardware aktual untuk titik fokus dan eksposur
    final isFocusSupported = controller.value.focusPointSupported;
    final isExposureSupported = controller.value.exposurePointSupported;

    // Jika perangkat sama sekali tidak mendukung titik fokus maupun eksposur
    // (misalnya sensor fixed-focus murni tanpa kustomisasi metering),
    // abaikan ketukan agar tidak memunculkan indikator palsu.
    if (!isFocusSupported && !isExposureSupported) return;

    // Normalisasi koordinat ke rentang [0.0, 1.0] untuk CameraController
    final nx = (local.dx / width).clamp(0.0, 1.0);
    final ny = (local.dy / height).clamp(0.0, 1.0);

    setState(() {
      _focusPosition = local;
    });

    _hideTimer?.cancel();
    _dismissTimer?.cancel();
    _exitController.reset();

    final isReducedMotion = AppMotion.isReducedMotion(context);
    if (isReducedMotion) {
      _entryController.value = 1;
    } else {
      _entryController.value = 0;
      final simulation = AppMotion.createSimulation(
        AppMotion.expressiveSpatialFast,
        start: 0,
        end: 1,
      );
      _entryController.animateWith(simulation);
    }

    // Haptic feedback saat mengetuk untuk memfokuskan (Material 3 standard)
    unawaited(HapticFeedback.lightImpact());

    // AF Assist Lamp: nyalakan senter sementara jika flashMode adalah always
    // pada kamera yang memiliki modul LED fisik untuk membantu penguncian
    // fokus di ruang gelap.
    final canUseAfAssist =
        widget.hasPhysicalFlash && widget.flashMode == FlashMode.always;
    if (canUseAfAssist) {
      _isAfAssistActive = true;
      try {
        await controller.setFlashMode(FlashMode.torch);
      } on Object catch (_) {
        // Abaikan jika modul tidak mendukung torch
      }
    }

    try {
      if (isFocusSupported && !_isFocusUnsupportedOnDevice) {
        await controller.setFocusPoint(Offset(nx, ny));
      }
    } on Object catch (_) {
      // Tandai modul kamera tidak mendukung titik fokus kustom
      _isFocusUnsupportedOnDevice = true;
    }

    try {
      if (isExposureSupported && !_isExposureUnsupportedOnDevice) {
        await controller.setExposurePoint(Offset(nx, ny));
      }
    } on Object catch (_) {
      // Tandai modul kamera tidak mendukung titik eksposur kustom
      _isExposureUnsupportedOnDevice = true;
    }

    // Reticle bertengger selama 1250ms, lalu memudar keluar selama 150ms.
    // Total waktu kemunculan: 1400ms (< 1600ms batas auto-hide unit test).
    _hideTimer = Timer(const Duration(milliseconds: 1250), () {
      if (!mounted) return;
      _deactivateAfAssist();
      if (isReducedMotion) {
        setState(() {
          _focusPosition = null;
        });
      } else {
        _exitController.forward(from: 0);
      }
    });

    _dismissTimer = Timer(const Duration(milliseconds: 1450), () {
      if (mounted) {
        _deactivateAfAssist();
        setState(() {
          _focusPosition = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    // Guard pencegah race condition layout pass terhadap controller
    // yang belum siap, telah di-dispose, atau mengalami runtime error.
    if (!controller.value.isInitialized || controller.value.hasError) {
      return const CameraLoadingIndicator();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          key: const ValueKey<String>('camera_preview_gesture_detector'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _handleTapDown(details, constraints),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),
              if (_focusPosition != null)
                _FocusReticle(
                  key: const ValueKey<String>('camera_focus_reticle'),
                  position: _focusPosition!,
                  entryAnimation: _entryController,
                  exitAnimation: _exitController,
                  colorScheme: widget.colorScheme,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Atom indikator reticle visual untuk interaksi touch-to-focus M3 Expressive.
class _FocusReticle extends StatelessWidget {
  const _FocusReticle({
    required this.position,
    required this.entryAnimation,
    required this.exitAnimation,
    required this.colorScheme,
    super.key,
  });

  final Offset position;
  final Animation<double> entryAnimation;
  final Animation<double> exitAnimation;
  final M3EColorScheme colorScheme;

  static const double _reticleSize = 64;

  @override
  Widget build(BuildContext context) {
    final isReducedMotion = AppMotion.isReducedMotion(context);

    return Positioned(
      left: position.dx - (_reticleSize / 2),
      top: position.dy - (_reticleSize / 2),
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: Listenable.merge([entryAnimation, exitAnimation]),
            builder: (context, _) {
              final entryProgress = entryAnimation.value;
              final exitProgress = Curves.easeIn.transform(
                exitAnimation.value.clamp(0.0, 1.0),
              );

              // 1. Skala Pegas Spasial M3 Expressive
              // Masuk: snap dari 1.35 ke 1.0 dengan overshoot pegas
              // Keluar: menyusut halus dari 1.0 ke 0.85
              final double scale;
              if (isReducedMotion) {
                scale = 1.0;
              } else {
                final entryScale = 1.35 - (0.35 * entryProgress);
                final exitScaleFactor = 1.0 - (0.15 * exitProgress);
                scale = entryScale * exitScaleFactor;
              }

              // 2. Opasitas Efek M3 Expressive (masuk cepat, keluar memudar)
              final entryOpacity = (entryProgress * 3.0).clamp(0.0, 1.0);
              final exitOpacity = 1.0 - exitProgress;
              final overallOpacity = (entryOpacity * exitOpacity).clamp(
                0.0,
                1.0,
              );

              // 3. Gelombang Gema Luar (Echo Ripple Wave)
              final rippleScale = 1.0 + (0.45 * entryProgress.clamp(0.0, 1.0));
              final rippleOpacity = isReducedMotion
                  ? 0.0
                  : ((1.0 - entryProgress.clamp(0.0, 1.0)) * 0.50 * exitOpacity)
                        .clamp(0.0, 1.0);

              return Opacity(
                opacity: overallOpacity,
                child: SizedBox(
                  width: _reticleSize,
                  height: _reticleSize,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // A. Gelombang Gema Luar (Echo Ripple)
                      if (rippleOpacity > 0.01)
                        Transform.scale(
                          scale: rippleScale,
                          child: Container(
                            width: _reticleSize,
                            height: _reticleSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.primary.withValues(
                                  alpha: rippleOpacity,
                                ),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                      // B. Cincin Fokus Utama M3 Expressive
                      Transform.scale(
                        scale: scale,
                        child: Container(
                          width: _reticleSize,
                          height: _reticleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                            boxShadow: [
                              // 1. Key Shadow (Tepi Presisi & Kontras)
                              BoxShadow(
                                color: colorScheme.scrim.withValues(
                                  alpha: 0.40,
                                ),
                                blurRadius: 2,
                                spreadRadius: 0.5,
                              ),
                              // 2. Ambient Shadow (Pendaran Halus Lembut)
                              BoxShadow(
                                color: colorScheme.scrim.withValues(
                                  alpha: 0.20,
                                ),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 4 Aksen Kuadran Kardinal
                              _CardinalFocusTicks(
                                color: colorScheme.primary,
                                shadowColor: colorScheme.scrim.withValues(
                                  alpha: 0.40,
                                ),
                              ),

                              // Titik Presisi Tengah
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.scrim.withValues(
                                        alpha: 0.40,
                                      ),
                                      blurRadius: 1.5,
                                      spreadRadius: 0.5,
                                    ),
                                    BoxShadow(
                                      color: colorScheme.scrim.withValues(
                                        alpha: 0.20,
                                      ),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Aksen kuadran kardinal pada cincin fokus Material 3 Expressive.
class _CardinalFocusTicks extends StatelessWidget {
  const _CardinalFocusTicks({required this.color, required this.shadowColor});

  final Color color;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(64, 64),
      painter: _CardinalTicksPainter(color: color, shadowColor: shadowColor),
    );
  }
}

class _CardinalTicksPainter extends CustomPainter {
  const _CardinalTicksPainter({required this.color, required this.shadowColor});

  final Color color;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const double tickLen = 4;

    final shadowPaint = Paint()
      ..color = shadowColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final tickPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    _drawTicks(canvas, center, radius, tickLen, shadowPaint);
    _drawTicks(canvas, center, radius, tickLen, tickPaint);
  }

  void _drawTicks(
    Canvas canvas,
    Offset center,
    double radius,
    double tickLen,
    Paint paint,
  ) {
    canvas
      ..drawLine(
        Offset(center.dx, center.dy - radius - 2),
        Offset(center.dx, center.dy - radius + tickLen),
        paint,
      )
      ..drawLine(
        Offset(center.dx, center.dy + radius + 2),
        Offset(center.dx, center.dy + radius - tickLen),
        paint,
      )
      ..drawLine(
        Offset(center.dx - radius - 2, center.dy),
        Offset(center.dx - radius + tickLen, center.dy),
        paint,
      )
      ..drawLine(
        Offset(center.dx + radius + 2, center.dy),
        Offset(center.dx + radius - tickLen, center.dy),
        paint,
      );
  }

  @override
  bool shouldRepaint(_CardinalTicksPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.shadowColor != shadowColor;
}
