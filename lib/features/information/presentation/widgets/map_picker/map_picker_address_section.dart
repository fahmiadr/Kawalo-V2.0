import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';
import 'package:kawalo_mobile/core/widgets/app_tooltip.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/map_picker/map_picker_overlay_state.dart';
import 'package:latlong2/latlong.dart' hide Path;

// ============================================================================
// MOLECULE: Coordinates Display (Real-time 60fps ValueListenable)
// ============================================================================

/// Teks penampil koordinat lintang dan bujur yang mendengarkan perubahan
/// posisi kamera secara real-time tanpa memicu rebuild pada kanvas peta.
class CoordinatesDisplay extends StatelessWidget {
  const CoordinatesDisplay({required this.centerListenable, super.key});

  final ValueListenable<LatLng> centerListenable;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;
    final style = AppTheme.emphasizedTypeScaleOf(
      context,
    ).labelMedium.copyWith(color: colorScheme.onSurface);

    return ValueListenableBuilder<LatLng>(
      valueListenable: centerListenable,
      builder: (context, center, _) {
        return Text(
          'Koordinat: '
          '${center.latitude.toStringAsFixed(6)}, '
          '${center.longitude.toStringAsFixed(6)}',
          style: style,
        );
      },
    );
  }
}

// ============================================================================
// MOLECULE: Address Error & Retry Action
// ============================================================================

/// Baris aksi error dan tombol coba lagi ketika resolusi alamat gagal,
/// mematuhi standar Material 3 Expressive dan WCAG AA touch target 48x48dp.
class _AddressErrorRetry extends StatelessWidget {
  const _AddressErrorRetry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;
    final typeScale = AppTheme.typeScaleOf(context);
    final emphasizedTypeScale = AppTheme.emphasizedTypeScaleOf(context);
    final linkColor = colorScheme.primary;

    return Text.rich(
      TextSpan(
        style: typeScale.bodySmall.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        text: 'Detail alamat jalan tidak tersedia',
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: AppTooltip(
              message: 'Coba lagi memuat alamat lokasi',
              child: AppTappable.builder(
                semanticLabel: 'Coba lagi memuat alamat lokasi',
                onTap: onRetry,
                builder: (context, state) {
                  final contentColor = state.pressed
                      ? linkColor.withValues(
                          alpha: 1.0 - AppStateLayer.pressedOpacity,
                        )
                      : linkColor;

                  return DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.borderExtraSmall,
                      border: state.focused
                          ? Border.all(color: linkColor)
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 4,
                        right: 2,
                        top: 1,
                        bottom: 1,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppSvgIcon(
                            KawaloVectors.reload,
                            size: 11,
                            color: contentColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Coba lagi',
                            style: emphasizedTypeScale.bodySmall.copyWith(
                              color: contentColor,
                              decoration: TextDecoration.underline,
                              decorationColor: contentColor,
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
        ],
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ============================================================================
// MOLECULE: Address Shimmer Skeleton
// ============================================================================

/// Skeleton shimmer memuat alamat dengan animasi shimmer berulang
/// yang mematuhi reduced motion dan anti layout-shift.
class _AddressShimmerSkeleton extends StatefulWidget {
  const _AddressShimmerSkeleton();

  @override
  State<_AddressShimmerSkeleton> createState() =>
      _AddressShimmerSkeletonState();
}

class _AddressShimmerSkeletonState extends State<_AddressShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDuration.extraLong4,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startOrStopAnimation();
  }

  void _startOrStopAnimation() {
    final isRunningInTest = WidgetsBinding.instance is! WidgetsFlutterBinding;
    if (isRunningInTest || AppMotion.isReducedMotion(context)) {
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
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final isReduced = AppMotion.isReducedMotion(context);

    final baseColor = colorScheme.surfaceContainerHigh;
    final highlightColor = colorScheme.surfaceContainerHighest;

    return RepaintBoundary(
      child: Semantics(
        label: 'Memuat alamat lokasi',
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final gradient = isReduced
                ? null
                : LinearGradient(
                    begin: Alignment(-2.0 + 4.0 * _controller.value, -0.3),
                    end: Alignment(-1.0 + 4.0 * _controller.value, 0.3),
                    colors: [baseColor, highlightColor, baseColor],
                    stops: const [0.0, 0.5, 1.0],
                  );

            return Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 180,
                    height: 10,
                    decoration: BoxDecoration(
                      color: gradient == null ? baseColor : null,
                      gradient: gradient,
                      borderRadius: AppRadius.borderExtraSmall,
                    ),
                  ),
                  AppSpacing.vGap25,
                  Container(
                    width: 110,
                    height: 10,
                    decoration: BoxDecoration(
                      color: gradient == null ? baseColor : null,
                      gradient: gradient,
                      borderRadius: AppRadius.borderExtraSmall,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// MOLECULE: Address Resolution Section
// ============================================================================

/// Area tampilan alamat 3 baris yang dipreservasi untuk mencegah
/// Cumulative Layout Shift (CLS) saat transisi loading, teks, error, atau
/// petunjuk manual.
class AddressResolutionSection extends StatelessWidget {
  const AddressResolutionSection({
    required this.state,
    required this.onRetry,
    super.key,
  });

  final MapPickerOverlayState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = AppTheme.typeScaleOf(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: ExcludeSemantics(
            child: AppSvgIcon.color(KawaloColorVectors.location1, size: 16),
          ),
        ),
        AppSpacing.hGap100,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppStateLayer.minTouchTarget,
              ),
              child: Stack(
                alignment: Alignment.topLeft,
                children: [
                  ExcludeSemantics(
                    child: Opacity(
                      opacity: 0,
                      child: Text(
                        ' \n \n ',
                        style: typeScale.bodySmall,
                        maxLines: 3,
                      ),
                    ),
                  ),
                  if (state.isResolvingAddress)
                    const _AddressShimmerSkeleton()
                  else if (state.resolvedAddress != null &&
                      state.resolvedAddress!.isNotEmpty)
                    Text(
                      state.resolvedAddress!,
                      style: typeScale.bodySmall.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (state.hasGeocodeError && !state.isLocatingUser)
                    _AddressErrorRetry(onRetry: onRetry)
                  else if (state.showGuidingHelper)
                    Text(
                      'Geser peta untuk menentukan titik secara manual',
                      style: typeScale.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
