import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';
import 'package:material_3_expressive/material_3_expressive.dart'
    show M3EStateLayerOverlay;

/// Komponen fondasi interaktif Material 3 Expressive (`AppMorphingSurface`)
/// yang menyatukan animasi pegas perubahan bentuk (*Spring Shape Morphing*),
/// skala netral 1.0 untuk stabilitas tata letak, dan lapisan ripple Material
/// (`materialInk: true` + [M3EStateLayerOverlay]).
///
/// Dirancang sebagai implementasi DRY terpusat untuk kartu, ubin gambar,
/// thumbnail, atau permukaan interaktif apa pun yang membutuhkan kompresi
/// sudut responsif dengan fisika pegas M3 Expressive.
class AppMorphingSurface extends StatefulWidget {
  /// Membuat instance [AppMorphingSurface].
  const AppMorphingSurface({
    super.key,
    this.child,
    this.overlay,
    this.builder,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.restingBorderRadius = AppRadius.borderMedium,
    this.pressedBorderRadius,
    this.pressedScale = 1.0,
    this.materialInk = true,
    this.stateLayerColor,
    this.border,
    this.semanticLabel,
    this.semanticButton = true,
    this.excludeSemantics = false,
    this.haptic = M3EHapticFeedback.light,
  });

  /// Garis batas opsional yang secara dinamis mengikuti lekukan sudut
  /// per-frame selama animasi morphing.
  final BorderSide? border;

  /// Widget konten utama di dalam area interaktif (misalnya [Hero] atau
  /// gambar).
  final Widget? child;

  /// Widget overlay opsional yang diletakkan di atas [child] dan ripple
  /// (misalnya badge urutan, tombol aksi hapus, atau loading indicator).
  ///
  /// Kontrol interaktif di dalam [overlay] (seperti tombol silang) akan
  /// menerima ketukan secara mandiri tanpa memicu [onTap] permukaan utama.
  final Widget? overlay;

  /// Builder kustom opsional jika tata letak membutuhkan akses langsung
  /// ke radius efektif per-frame dan status interaksi [AppInteractionState].
  final Widget Function(
    BuildContext context,
    BorderRadius effectiveRadius,
    AppInteractionState state,
  )?
  builder;

  /// Callback saat permukaan diketuk.
  final VoidCallback? onTap;

  /// Callback saat permukaan ditekan lama.
  final VoidCallback? onLongPress;

  /// Menentukan apakah permukaan merespons interaksi.
  final bool enabled;

  /// [BorderRadius] saat permukaan dalam kondisi istirahat (default: 12dp).
  final BorderRadius restingBorderRadius;

  /// [BorderRadius] saat permukaan ditekan. Jika bernilai `null`, otomatis
  /// dihitung via [AppRadius.compressOnPress] (sudut perimeter $\ge 12\text{dp}$
  /// terkompresi ke $8\text{dp}$, sudut dalam tetap dipertahankan).
  final BorderRadius? pressedBorderRadius;

  /// Skala animasi penekanan (default `1.0` untuk mempertahankan integritas
  /// grid dan target sentuh tanpa celah visual).
  final double pressedScale;

  /// Menentukan apakah lapisan pendaran ripple Material 3 ditampilkan.
  final bool materialInk;

  /// Warna lapisan ripple / state layer (default: `colorScheme.onSurface`).
  final Color? stateLayerColor;

  /// Label aksesibilitas untuk screen reader.
  final String? semanticLabel;

  /// Menentukan apakah semantik memperlakukan komponen sebagai tombol.
  final bool semanticButton;

  /// Menentukan apakah semantik child diabaikan.
  final bool excludeSemantics;

  /// Tingkat intensitas haptic feedback saat ditekan.
  final M3EHapticFeedback haptic;

  @override
  State<AppMorphingSurface> createState() => _AppMorphingSurfaceState();
}

class _AppMorphingSurfaceState extends State<AppMorphingSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _morphController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController.unbounded(vsync: this);
  }

  @override
  void didUpdateWidget(covariant AppMorphingSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _isPressed) {
      _handlePressChanged(false, isReducedMotion: true);
    }
  }

  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  void _handlePressChanged(bool isPressed, {required bool isReducedMotion}) {
    if (_isPressed == isPressed) return;
    setState(() => _isPressed = isPressed);

    final target = isPressed ? 1.0 : 0.0;
    if (isReducedMotion) {
      _morphController.value = target;
      return;
    }

    final simulation = AppMotion.createSimulation(
      AppMotion.expressiveSpatialPress,
      start: _morphController.value,
      end: target,
      velocity: _morphController.velocity,
    );
    _morphController.animateWith(simulation).whenCompleteOrCancel(() {
      if (mounted) {
        if (_morphController.value > 0.95 && _isPressed) {
          _morphController.value = 1.0;
        } else if (_morphController.value < 0.05 && !_isPressed) {
          _morphController.value = 0.0;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.colorSchemeOf(context);
    final isReducedMotion = AppMotion.isReducedMotion(context);
    final restingRadius = widget.restingBorderRadius;
    final pressedRadius =
        widget.pressedBorderRadius ?? AppRadius.compressOnPress(restingRadius);

    return AnimatedBuilder(
      animation: _morphController,
      builder: (context, _) {
        final effectiveRadius = AppRadius.lerpMorph(
          restingRadius,
          pressedRadius,
          _morphController.value,
        );

        return ClipRRect(
          borderRadius: effectiveRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppTappable.builder(
                onTap: widget.enabled ? widget.onTap : null,
                onLongPress: widget.enabled ? widget.onLongPress : null,
                enabled: widget.enabled,
                pressedScale: widget.pressedScale,
                materialInk: widget.materialInk,
                semanticLabel: widget.semanticLabel,
                semanticButton: widget.semanticButton,
                excludeSemantics: widget.excludeSemantics,
                haptic: widget.haptic,
                onStateChanged: (state) {
                  if (!mounted) return;
                  if (!widget.enabled) {
                    if (_isPressed) {
                      _handlePressChanged(
                        false,
                        isReducedMotion: isReducedMotion,
                      );
                    }
                    return;
                  }
                  _handlePressChanged(
                    state.pressed,
                    isReducedMotion: isReducedMotion,
                  );
                },
                builder: (context, state) {
                  final content = widget.builder != null
                      ? widget.builder!(context, effectiveRadius, state)
                      : widget.child;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ?content,
                      if (widget.border != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              position: DecorationPosition.foreground,
                              decoration: BoxDecoration(
                                borderRadius: effectiveRadius,
                                border: Border.fromBorderSide(widget.border!),
                              ),
                            ),
                          ),
                        ),
                      if (widget.materialInk)
                        Positioned.fill(
                          child: M3EStateLayerOverlay(
                            state: state,
                            color:
                                widget.stateLayerColor ?? colorScheme.onSurface,
                            shape: RoundedRectangleBorder(
                              borderRadius: effectiveRadius,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (widget.overlay != null) widget.overlay!,
            ],
          ),
        );
      },
    );
  }
}
