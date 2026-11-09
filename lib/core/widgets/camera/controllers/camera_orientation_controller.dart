import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kawalo_mobile/core/services/device_orientation_service.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';

/// Mengelola orientasi fisik perangkat untuk kontrol UI kamera: putaran
/// kontrol, sensor akselerometer, dan animasi "teleport" badge kuota.
///
/// Pembaruan UI dilakukan lewat `update` (biasanya `setState` milik State) dan
/// pengecekan `mounted` lewat `isMounted`, sehingga urutan dan waktu mutasi
/// state sama persis dengan saat logika ini masih berada di State.
class CameraOrientationController {
  CameraOrientationController({
    required TickerProvider vsync,
    required DeviceOrientation initialOrientation,
    required DeviceOrientationSensorService? sensorService,
    required bool Function() isMounted,
    required bool Function() isReducedMotion,
    required void Function(VoidCallback fn) update,
    VoidCallback? onDeviceOrientationChanged,
  }) : _isMounted = isMounted,
       _isReducedMotion = isReducedMotion,
       _update = update,
       _onDeviceOrientationChanged = onDeviceOrientationChanged,
       _ownsSensorService = sensorService == null,
       deviceOrientation = initialOrientation,
       turns = initialOrientation.turns,
       activeBadgeOrientation = initialOrientation {
    _badgeTeleportController = AnimationController(
      vsync: vsync,
      duration: teleportHalfDuration,
      value: 1,
    );
    badgeFadeAnimation = CurvedAnimation(
      parent: _badgeTeleportController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    badgeScaleAnimation = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(
        parent: _badgeTeleportController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );

    _sensorService =
        sensorService ??
        DefaultDeviceOrientationSensorService(
          initialOrientation: initialOrientation,
        );
    _subscription = _sensorService.onOrientationChanged.listen(
      _onSensorOrientation,
    );
  }

  static const Duration teleportHalfDuration = AppDuration.medium1;

  final bool Function() _isMounted;
  final bool Function() _isReducedMotion;
  final void Function(VoidCallback fn) _update;
  final VoidCallback? _onDeviceOrientationChanged;
  final bool _ownsSensorService;

  late final AnimationController _badgeTeleportController;
  late final DeviceOrientationSensorService _sensorService;
  StreamSubscription<DeviceOrientation>? _subscription;
  int _teleportGeneration = 0;

  late final Animation<double> badgeFadeAnimation;
  late final Animation<double> badgeScaleAnimation;

  /// Orientasi fisik perangkat terkini.
  DeviceOrientation deviceOrientation;

  /// Akumulasi putaran kontrol UI (dalam satuan *turns*) menuju orientasi
  /// terkini lewat jalur terpendek.
  double turns;

  /// Orientasi slot tempat badge kuota saat ini ditampilkan.
  DeviceOrientation activeBadgeOrientation;

  void pauseSensor() => _subscription?.pause();

  void resumeSensor() => _subscription?.resume();

  void _onSensorOrientation(DeviceOrientation newOrientation) {
    if (!_isMounted()) return;
    updateOrientation(newOrientation);
  }

  void updateOrientation(DeviceOrientation newOrientation) {
    if (deviceOrientation != newOrientation) {
      final target = newOrientation.turns;
      var delta = (target - turns) % 1.0;
      if (delta > 0.5) delta -= 1.0;
      if (delta < -0.5) delta += 1.0;
      _update(() {
        deviceOrientation = newOrientation;
        turns += delta;
        _onDeviceOrientationChanged?.call();
      });
    }
    _handleBadgeOrientationTransition(newOrientation);
  }

  void _handleBadgeOrientationTransition(DeviceOrientation newOrientation) {
    if (!_isMounted()) return;
    if (_isReducedMotion()) {
      _teleportGeneration++;
      if (_badgeTeleportController.isAnimating) {
        _badgeTeleportController.stop();
      }
      _update(() {
        activeBadgeOrientation = newOrientation;
        _badgeTeleportController.value = 1;
      });
      return;
    }

    if (activeBadgeOrientation == newOrientation &&
        _badgeTeleportController.value == 1) {
      return;
    }

    final generation = ++_teleportGeneration;
    if (_badgeTeleportController.isAnimating) {
      _badgeTeleportController.stop();
    }
    unawaited(_runTeleport(generation));
  }

  /// Durasi satu fase teleport, proporsional terhadap sisa [ratio] animasi
  /// dengan batas bawah 20ms.
  static Duration computeTeleportDuration(double ratio) {
    final clampedRatio = ratio.clamp(0.0, 1.0);
    final durationMs = (teleportHalfDuration.inMilliseconds * clampedRatio)
        .round();
    return durationMs > 20
        ? Duration(milliseconds: durationMs)
        : const Duration(milliseconds: 20);
  }

  Future<void> _runTeleport(int generation) async {
    try {
      while (_isMounted() && generation == _teleportGeneration) {
        if (activeBadgeOrientation != deviceOrientation) {
          // Fase 1: Dissolve / Fade-out badge yang aktif di slot lama
          if (_badgeTeleportController.value > 0) {
            final fadeOutDuration = computeTeleportDuration(
              _badgeTeleportController.value,
            );
            try {
              await _badgeTeleportController.animateTo(
                0,
                duration: fadeOutDuration,
                curve: Curves.easeIn,
              );
            } on Object catch (_) {}
          }

          if (!_isMounted() || generation != _teleportGeneration) return;

          // Fase Hand-off: Ganti slot saat opacity tepat 0.0
          // Menggunakan orientasi fisik perangkat terkini
          final currentTarget = deviceOrientation;
          _update(() {
            activeBadgeOrientation = currentTarget;
          });

          if (!_isMounted() || generation != _teleportGeneration) return;

          // Fase 2: Materialize / Fade-in badge pada slot tujuan
          final fadeInDuration = computeTeleportDuration(
            1.0 - _badgeTeleportController.value,
          );
          try {
            await _badgeTeleportController.animateTo(
              1,
              duration: fadeInDuration,
            );
          } on Object catch (_) {}
        } else if (_badgeTeleportController.value < 1) {
          // Orientasi fisik sudah sesuai namun animasi fade-in terputus
          final fadeInDuration = computeTeleportDuration(
            1.0 - _badgeTeleportController.value,
          );
          try {
            await _badgeTeleportController.animateTo(
              1,
              duration: fadeInDuration,
            );
          } on Object catch (_) {}
        } else {
          // Orientasi sinkron dan opasitas telah 100% penuh
          break;
        }
      }
    } finally {
      if (_isMounted() && generation == _teleportGeneration) {
        if (activeBadgeOrientation != deviceOrientation) {
          _update(() {
            activeBadgeOrientation = deviceOrientation;
          });
        }
        if (_badgeTeleportController.value != 1) {
          _badgeTeleportController.value = 1;
        }
      }
    }
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    if (_ownsSensorService) {
      _sensorService.dispose();
    }
    _teleportGeneration++;
    _badgeTeleportController.dispose();
  }
}
