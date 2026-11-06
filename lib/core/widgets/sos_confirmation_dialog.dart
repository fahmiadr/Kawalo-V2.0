import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kawalo_mobile/core/theme/app_elevation.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_shape.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_progress_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

/// Menampilkan dialog darurat SOS layar penuh (Fullscreen) dengan pengamanan:
/// 1. Sentuh lama (Hold) 3 detik untuk mengirim sinyal darurat.
/// 2. Geser (Slide to Cancel) untuk membatalkan dengan teks 'Batal' statis
///    memudar.
/// 3. Auto-batal otomatis setelah 20 detik tanpa interaksi.
///
/// Mengembalikan `true` jika SOS terpicu, atau `false`/`null` jika dibatalkan.
Future<bool?> showSosConfirmationDialog(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierLabel: 'Pemicu Darurat SOS',
    transitionDuration: AppMotion.long2,
    pageBuilder: (context, animation, secondaryAnimation) {
      return const SosConfirmationDialog();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: AppMotion.emphasizedDecelerate,
          ),
        ),
        child: child,
      );
    },
  );
}

/// Dialog Fullscreen pemicu SOS darurat.
class SosConfirmationDialog extends StatefulWidget {
  /// Membuat instance [SosConfirmationDialog].
  const SosConfirmationDialog({
    super.key,
    this.holdDuration = const Duration(seconds: 3),
    this.autoCancelTimeout = 20,
  });

  /// Durasi menahan tombol utama untuk memicu sinyal SOS (default: 3 detik).
  final Duration holdDuration;

  /// Batas waktu ketidakaktifan dalam detik sebelum auto-batal
  /// (default: 20 detik).
  final int autoCancelTimeout;

  @override
  State<SosConfirmationDialog> createState() => _SosConfirmationDialogState();
}

class _SosConfirmationDialogState extends State<SosConfirmationDialog>
    with TickerProviderStateMixin {
  late AnimationController _holdController;
  late int _autoCancelRemaining;
  Timer? _autoCancelTimer;
  bool _isHolding = false;
  bool _isSosTriggered = false;
  int? _lastVibratedSecond;

  @override
  void initState() {
    super.initState();
    _autoCancelRemaining = widget.autoCancelTimeout;

    _holdController = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    )
      ..addListener(() {
        if (_isHolding) {
          final remaining =
              (widget.holdDuration.inSeconds * (1.0 - _holdController.value))
                  .ceil();
          if (remaining != _lastVibratedSecond && remaining > 0) {
            _lastVibratedSecond = remaining;
            HapticFeedback.mediumImpact();
          }
        }
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_isSosTriggered) {
          _triggerSos();
        }
      });

    _startAutoCancelTimer();
  }

  void _startAutoCancelTimer() {
    _autoCancelTimer?.cancel();
    _autoCancelTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isHolding) return;

      if (_autoCancelRemaining > 1) {
        setState(() {
          _autoCancelRemaining--;
        });
      } else {
        _autoCancelTimer?.cancel();
        if (mounted && !_isSosTriggered) {
          Navigator.of(context).pop(false);
        }
      }
    });
  }

  void _onHoldStart() {
    if (_isSosTriggered) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _isHolding = true;
    });
    _holdController.forward();
  }

  void _onHoldEnd() {
    if (_isSosTriggered) return;
    _lastVibratedSecond = null;
    setState(() {
      _isHolding = false;
    });
    if (!_holdController.isCompleted) {
      _holdController.reset();
    }
  }

  void _triggerSos() {
    _isSosTriggered = true;
    HapticFeedback.heavyImpact();
    _autoCancelTimer?.cancel();
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _onCancelSlideTriggered() {
    _autoCancelTimer?.cancel();
    _holdController.stop();
    if (mounted && !_isSosTriggered) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  void dispose() {
    _autoCancelTimer?.cancel();
    _holdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final emphasizedTypeScale = theme.typography.emphasized;
    final isReducedMotion = AppMotion.isReducedMotion(context);

    final holdProgress = _holdController.value;
    final remainingSeconds =
        (widget.holdDuration.inSeconds * (1.0 - holdProgress)).ceil();

    return ColoredBox(
      color: colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // 1. M3E Full-Screen Header (tanpa close button)
            SizedBox(
              height: 64,
              child: Padding(
                padding: AppSpacing.paddingHorizontal300,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Darurat SOS',
                    style: emphasizedTypeScale.titleLarge.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),

            // 2. M3E Divider
            Divider(height: 1, color: colorScheme.outlineVariant),

            // 3. Body Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space300,
                  vertical: AppSpacing.space200,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 3a. Daftar Aksi "Anda akan:"
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSpacing.vGapSm,
                        Text(
                          'Anda akan:',
                          style: emphasizedTypeScale.titleSmall.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        AppSpacing.vGapSm,
                        const _ActionListItem(
                          icon: KawaloVectors.siren,
                          text: 'Menyiarkan sinyal bahaya ke seluruh tim',
                        ),
                        AppSpacing.vGapXs,
                        const _ActionListItem(
                          icon: KawaloVectors.locationUser03,
                          text: 'Membagikan lokasi terkini Anda',
                        ),
                      ],
                    ),

                    // 3b. Tombol Utama Sentuh Lama (3 Detik)
                    Column(
                      children: [
                        Semantics(
                          button: true,
                          label:
                              'Tombol kirim SOS. Tahan 3 detik untuk mengirim',
                          child: Listener(
                            onPointerDown: (_) => _onHoldStart(),
                            onPointerUp: (_) => _onHoldEnd(),
                            onPointerCancel: (_) => _onHoldEnd(),
                            child: Center(
                              child: SizedBox(
                                width: 190,
                                height: 190,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Ring Progres Latar Belakang (Track)
                                    SizedBox(
                                      width: 180,
                                      height: 180,
                                      child: AppProgressIndicator.circular(
                                        value: 1,
                                        strokeWidth: 10,
                                        color: colorScheme.errorContainer
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),

                                    // Ring Progres Dinamis (100% -> 0%)
                                    SizedBox(
                                      width: 180,
                                      height: 180,
                                      child: AppProgressIndicator.circular(
                                        value: isReducedMotion
                                            ? 1.0
                                            : (1.0 - holdProgress),
                                        strokeWidth: 10,
                                        color: colorScheme.error,
                                      ),
                                    ),

                                    // Badan Tombol Merah Darurat
                                    AnimatedScale(
                                      scale: _isHolding ? 0.95 : 1.0,
                                      duration: AppMotion.short2,
                                      curve: AppMotion.standard,
                                      child: Container(
                                        width: 148,
                                        height: 148,
                                        decoration: ShapeDecoration(
                                          shape: const CircleBorder(),
                                          color: colorScheme.error,
                                          shadows: [
                                            BoxShadow(
                                              color: colorScheme.error
                                                  .withValues(alpha: 0.35),
                                              blurRadius: _isHolding ? 24 : 14,
                                              spreadRadius: _isHolding ? 4 : 1,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: _isHolding
                                              ? Text(
                                                  '$remainingSeconds',
                                                  style: emphasizedTypeScale
                                                      .displayLarge
                                                      .copyWith(
                                                    color: colorScheme.onError,
                                                  ),
                                                )
                                              : Padding(
                                                  padding: AppSpacing
                                                      .paddingHorizontal200,
                                                  child: Text(
                                                    'Sentuh lama 3 detik '
                                                    'untuk memulai',
                                                    style: emphasizedTypeScale
                                                        .titleMedium
                                                        .copyWith(
                                                      color:
                                                          colorScheme.onError,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 3c. Slider Geser untuk Batal (M3E FullScreen Action)
                    _SlideToCancelWidget(
                      onCancelled: _onCancelSlideTriggered,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget slider geser untuk membatalkan SOS.
///
/// Teks 'Batal' berada statis di sebelah kanan thumb dan memudar saat thumb
/// digeser.
class _SlideToCancelWidget extends StatefulWidget {
  const _SlideToCancelWidget({required this.onCancelled});

  final VoidCallback onCancelled;

  @override
  State<_SlideToCancelWidget> createState() => _SlideToCancelWidgetState();
}

class _SlideToCancelWidgetState extends State<_SlideToCancelWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _snapBackController;
  double _dragOffset = 0;
  bool _isCompleted = false;

  static const double _trackHeight = 60;
  static const double _thumbSize = 50;
  static const double _padding = AppSpacing.space50;

  @override
  void initState() {
    super.initState();
    _snapBackController = AnimationController(
      vsync: this,
      duration: AppMotion.short3,
    )..addListener(() {
        setState(() {
          _dragOffset = _snapBackController.value;
        });
      });
  }

  @override
  void dispose() {
    _snapBackController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_isCompleted || maxDrag <= 0) return;
    _snapBackController.stop();

    final delta = details.primaryDelta ?? 0.0;
    setState(() {
      _dragOffset = (_dragOffset + delta).clamp(0.0, maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details, double maxDrag) {
    if (_isCompleted || maxDrag <= 0) return;

    // Aksi batal dipicu KETIKA thumb dilepas di ujung (>= 80% / maxDrag)
    if (_dragOffset >= maxDrag * 0.80) {
      _isCompleted = true;
      setState(() {
        _dragOffset = maxDrag;
      });
      widget.onCancelled();
    } else {
      // Jika dilepas sebelum 80%, kembali elastis ke posisi awal
      if (AppMotion.isReducedMotion(context)) {
        _snapBackController.animateTo(
          0,
          duration: AppMotion.short4,
          curve: AppEasing.standardDecelerate,
        );
      } else {
        final simulation = AppMotion.spatialDefault.createSimulation(
          start: _dragOffset,
          end: 0,
          velocity: details.primaryVelocity ?? 0,
        );
        _snapBackController.animateWith(simulation);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final emphasizedTypeScale = theme.typography.emphasized;

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final maxDrag = (trackWidth - _thumbSize - (_padding * 2))
            .clamp(0.0, double.infinity);

        // Snap ke ujung saat >= 80%, namun dapat kembali jika digeser ke kiri
        final isSnappedToEnd = maxDrag > 0 && (_dragOffset >= maxDrag * 0.80);
        final visualOffset = isSnappedToEnd ? maxDrag : _dragOffset;

        final dragRatio = maxDrag > 0 ? (visualOffset / maxDrag) : 0.0;
        final textOpacity = (1.0 - dragRatio).clamp(0.0, 1.0);

        return Container(
          width: trackWidth,
          height: _trackHeight,
          decoration: ShapeDecoration(
            shape: AppShape.full.copyWith(
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            color: colorScheme.surfaceContainerHighest,
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Teks 'Batal' Statis di sebelah kanan thumb yang memudar
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: _thumbSize + (_padding * 2) + AppSpacing.space150,
                  ),
                  child: Opacity(
                    opacity: textOpacity,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Batal',
                          style: emphasizedTypeScale.titleMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        AppSpacing.gapSm,
                        AppSvgIcon(
                          KawaloVectors.arrowRight02,
                          size: 20,
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Thumb/Knob yang dapat digeser
              Align(
                alignment: Alignment.centerLeft,
                child: Transform.translate(
                  offset: Offset(_padding + visualOffset, 0),
                  child: Semantics(
                    slider: true,
                    label: 'Slider geser untuk membatalkan SOS',
                    value: '${(dragRatio * 100).round()}%',
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) =>
                          _onDragUpdate(details, maxDrag),
                      onHorizontalDragEnd: (details) =>
                          _onDragEnd(details, maxDrag),
                      child: Container(
                        width: _thumbSize,
                        height: _thumbSize,
                        decoration: ShapeDecoration(
                          shape: CircleBorder(
                            side: BorderSide(
                              color: colorScheme.outlineVariant,
                              width: 1.5,
                            ),
                          ),
                          color: colorScheme.surface,
                          shadows: AppElevation.shadows(
                            AppElevation.level2,
                            shadowColor: colorScheme.shadow,
                          ),
                        ),
                        child: Center(
                          child: AppSvgIcon(
                            KawaloVectors.cancel01,
                            size: 24,
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Item daftar aksi dengan ikon dan teks untuk bagian informasi SOS.
class _ActionListItem extends StatelessWidget {
  const _ActionListItem({required this.icon, required this.text});

  /// Path aset ikon SVG.
  final String icon;

  /// Teks deskripsi aksi.
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: AppSpacing.paddingVerticalXs,
      child: Row(
        children: [
          AppSvgIcon(
            icon,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          AppSpacing.hGap150,
          Expanded(
            child: Text(
              text,
              style: theme.typeScale.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
