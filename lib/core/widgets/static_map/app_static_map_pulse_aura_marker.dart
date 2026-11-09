import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/widgets/app_static_map.dart';

/// Widget pembungkus penanda dengan animasi aura idle (pulsing radar beacon)
/// untuk membedakan penanda kustom aplikasi dari elemen kartografi
/// raster statis OpenStreetMap.
///
/// Mematuhi standar aksesibilitas WCAG AA dan [AppMotion.isReducedMotion].
class AppStaticMapPulseAuraMarker extends StatefulWidget {
  const AppStaticMapPulseAuraMarker({
    required this.child,
    required this.color,
    required this.coreSize,
    required this.showAura,
    super.key,
  });

  final Widget child;
  final Color color;
  final double coreSize;
  final bool showAura;

  @override
  State<AppStaticMapPulseAuraMarker> createState() =>
      AppStaticMapPulseAuraMarkerState();
}

class AppStaticMapPulseAuraMarkerState
    extends State<AppStaticMapPulseAuraMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startOrStopAnimation();
  }

  @override
  void didUpdateWidget(covariant AppStaticMapPulseAuraMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showAura != widget.showAura) {
      _startOrStopAnimation();
    }
  }

  void _startOrStopAnimation() {
    if (!widget.showAura) {
      _controller.stop();
      return;
    }

    if (AppMotion.isReducedMotion(context)) {
      _controller
        ..stop()
        ..value = 0.5;
      return;
    }

    // Di lingkungan widget test (di mana tester.pumpAndSettle() sering
    // dipanggil), animasi berulang tanpa henti dicegah agar tidak memicu
    // timeout, kecuali jika diizinkan secara eksplisit oleh pengujian.
    final isRunningInTest =
        WidgetsBinding.instance is! WidgetsFlutterBinding &&
        // The marker is the only consumer of this test-only flag outside the
        // library that declares it.
        // ignore: invalid_use_of_visible_for_testing_member
        !AppStaticMap.debugEnableAuraAnimationInTests;

    if (isRunningInTest) {
      _controller
        ..stop()
        ..value = 0.5;
      return;
    }

    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAura) {
      return widget.child;
    }

    final isReduced = AppMotion.isReducedMotion(context);
    final auraColor = widget.color;
    final coreSize = widget.coreSize;
    final maxExpansion = (coreSize * 0.85).clamp(10.0, 20.0);

    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (isReduced)
            // Mode hemat gerak (Reduced Motion): Halo statis beropasitas lembut
            Positioned(
              left: -maxExpansion * 0.5,
              top: -maxExpansion * 0.5,
              right: -maxExpansion * 0.5,
              bottom: -maxExpansion * 0.5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: auraColor.withValues(alpha: 0.18),
                  border: Border.all(
                    color: auraColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
              ),
            )
          else
            // Mode normal: Animasi denyut aura idle terus menerus
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                // Gelombang luar yang membesar dan memudar
                final outerProgress = Curves.easeOutCubic.transform(t);
                final outerOffset = maxExpansion * outerProgress;
                final outerOpacity = (1.0 - outerProgress) * 0.45;

                // Gelombang dalam (breathing halo) yang berdenyut lembut
                final innerProgress = t < 0.5 ? t * 2 : (1.0 - t) * 2;
                final innerOffset = maxExpansion * 0.35 * innerProgress;
                final innerOpacity = 0.14 + (0.12 * innerProgress);

                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Cincin radar terluar
                    Positioned(
                      left: -outerOffset,
                      top: -outerOffset,
                      right: -outerOffset,
                      bottom: -outerOffset,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: auraColor.withValues(
                            alpha: outerOpacity * 0.4,
                          ),
                          border: Border.all(
                            color: auraColor.withValues(alpha: outerOpacity),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    // Halo lembut di dekat inti marker
                    Positioned(
                      left: -innerOffset,
                      top: -innerOffset,
                      right: -innerOffset,
                      bottom: -innerOffset,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: auraColor.withValues(alpha: innerOpacity),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          // Penanda inti (Pin / Dot) tepat di tengah (0, 0)
          widget.child,
        ],
      ),
    );
  }
}
