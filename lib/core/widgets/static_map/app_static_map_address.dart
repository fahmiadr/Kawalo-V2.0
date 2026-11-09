import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';
import 'package:kawalo_mobile/core/widgets/app_tooltip.dart';

/// Widget penyaji alamat hasil reverse geocoding dengan loading shimmer
/// dan tombol retry.
class AppStaticMapAddress extends StatefulWidget {
  const AppStaticMapAddress({
    required this.latitude,
    required this.longitude,
    required this.service,
    this.address,
    this.onAddressResolved,
    super.key,
  });

  final double latitude;
  final double longitude;
  final String? address;
  final ReverseGeocodeService service;
  final ValueChanged<String?>? onAddressResolved;

  @override
  State<AppStaticMapAddress> createState() => AppStaticMapAddressState();
}

class AppStaticMapAddressState extends State<AppStaticMapAddress>
    with SingleTickerProviderStateMixin {
  String? _address;
  bool _isLoading = false;
  int _requestId = 0;
  AppCancellationToken? _cancelToken;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: AppDuration.extraLong4,
    );

    if (widget.address != null) {
      _address = widget.address;
      _isLoading = false;
    } else {
      _fetchAddress();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      _startShimmerAnimation();
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppStaticMapAddress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.address != null) {
      _cancelToken?.cancel();
      if (oldWidget.address != widget.address) {
        setState(() {
          _address = widget.address;
          _isLoading = false;
        });
        _shimmerController.stop();
      }
      return;
    }

    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude ||
        oldWidget.service != widget.service ||
        oldWidget.address != null) {
      _startShimmerAnimation();
      _fetchAddress();
    }
  }

  void _startShimmerAnimation() {
    if (AppMotion.isReducedMotion(context)) {
      _shimmerController
        ..stop()
        ..value = 0.5;
    } else if (!_shimmerController.isAnimating) {
      _shimmerController.repeat();
    }
  }

  void _retry() {
    if (_isLoading) return;
    _startShimmerAnimation();
    _fetchAddress();
  }

  Future<void> _fetchAddress() async {
    _cancelToken?.cancel();
    final cancelToken = DioCancellationToken();
    _cancelToken = cancelToken;
    final currentRequestId = ++_requestId;

    setState(() {
      _isLoading = true;
    });

    final result = await widget.service.reverseGeocode(
      latitude: widget.latitude,
      longitude: widget.longitude,
      cancelToken: cancelToken,
    );

    if (!mounted || currentRequestId != _requestId) return;
    if (result.isCancelled) return;

    setState(() {
      _address = result.address;
      _isLoading = false;
    });
    _shimmerController.stop();
    widget.onAddressResolved?.call(result.address);
  }

  Widget _buildShimmerSkeleton(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final isReduced = AppMotion.isReducedMotion(context);

    final baseColor = colorScheme.surfaceContainerHigh;
    final highlightColor = colorScheme.surfaceContainerHighest;

    return RepaintBoundary(
      child: Semantics(
        label: 'Memuat alamat lokasi',
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            final gradient = isReduced
                ? null
                : LinearGradient(
                    begin: Alignment(
                      -2.0 + 4.0 * _shimmerController.value,
                      -0.3,
                    ),
                    end: Alignment(-1.0 + 4.0 * _shimmerController.value, 0.3),
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

  Widget _buildErrorWithRetry(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;
    final linkColor = colorScheme.primary;

    return Text.rich(
      TextSpan(
        style: typeScale.labelSmall.copyWith(
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
                onTap: _retry,
                builder: (context, state) {
                  final contentColor = state.pressed
                      ? linkColor.withValues(alpha: 0.7)
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
                            style: emphasizedTypeScale.labelSmall.copyWith(
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

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final emphasizedTypeScale = theme.typography.emphasized;

    final hasAddress = _address != null && _address!.trim().isNotEmpty;

    return Padding(
      padding: AppSpacing.paddingHorizontalXs,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: ExcludeSemantics(
              child: AppSvgIcon.color(KawaloColorVectors.location1, size: 16),
            ),
          ),
          AppSpacing.hGapXs,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppStateLayer.minTouchTarget,
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: _isLoading
                      ? _buildShimmerSkeleton(context)
                      : (hasAddress
                            ? Text(
                                _address!,
                                style: emphasizedTypeScale.labelSmall.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              )
                            : _buildErrorWithRetry(context)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
