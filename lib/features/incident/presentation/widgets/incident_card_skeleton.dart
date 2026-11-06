import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_card.dart';

/// Skeleton loader untuk [IncidentCard] dengan animasi shimmer halus
/// sesuai spesifikasi Material 3 Expressive dan menghormati reduced motion,
/// serasi dan konsisten dengan komponen skeleton fitur Guest.
class IncidentCardSkeleton extends StatefulWidget {
  /// Membuat instance [IncidentCardSkeleton].
  const IncidentCardSkeleton({super.key});

  @override
  State<IncidentCardSkeleton> createState() => _IncidentCardSkeletonState();
}

class _IncidentCardSkeletonState extends State<IncidentCardSkeleton>
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
    if (AppMotion.isReducedMotion(context)) {
      _controller
        ..stop()
        ..value = 0.5;
    } else if (!_controller.isAnimating) {
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

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final gradient = isReduced
            ? null
            : LinearGradient(
                begin: Alignment(-2.0 + 4.0 * _controller.value, -0.3),
                end: Alignment(-1.0 + 4.0 * _controller.value, 0.3),
                colors: [
                  baseColor,
                  highlightColor,
                  baseColor,
                ],
                stops: const [0.0, 0.5, 1.0],
              );

        return AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space200,
            vertical: AppSpacing.space150,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Skeleton: Avatar 40x40 & Teks ───────────────────
              Row(
                children: [
                  _buildBox(
                    width: 40,
                    height: 40,
                    borderRadius: AppRadius.borderMedium,
                    gradient: gradient,
                    color: baseColor,
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            _buildBox(
                              width: 140,
                              height: 16,
                              borderRadius: AppRadius.borderSmall,
                              gradient: gradient,
                              color: baseColor,
                            ),
                            const Spacer(),
                            _buildBox(
                              width: 16,
                              height: 16,
                              borderRadius: AppRadius.borderExtraSmall,
                              gradient: gradient,
                              color: baseColor,
                            ),
                          ],
                        ),
                        AppSpacing.vGap25,
                        _buildBox(
                          width: 110,
                          height: 12,
                          borderRadius: AppRadius.borderSmall,
                          gradient: gradient,
                          color: baseColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              AppSpacing.vGapSm,

              // ── Tag Kategori Skeleton ──────────────────────────────────
              _buildBox(
                width: 76,
                height: 24,
                borderRadius: AppRadius.borderFull,
                gradient: gradient,
                color: baseColor,
              ),

              // ── Garis Pemisah (Divider) ────────────────────────────────
              const Padding(
                padding: AppSpacing.paddingVertical150,
                child: AppDivider(),
              ),

              // ── Baris Deskripsi Skeleton ───────────────────────────────
              Row(
                children: [
                  _buildBox(
                    width: 20,
                    height: 20,
                    borderRadius: AppRadius.borderExtraSmall,
                    gradient: gradient,
                    color: baseColor,
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: _buildBox(
                      width: double.infinity,
                      height: 14,
                      borderRadius: AppRadius.borderSmall,
                      gradient: gradient,
                      color: baseColor,
                    ),
                  ),
                ],
              ),

              AppSpacing.vGap50,

              // ── Baris Waktu & Status Skeleton ──────────────────────────
              Row(
                children: [
                  _buildBox(
                    width: 20,
                    height: 20,
                    borderRadius: AppRadius.borderExtraSmall,
                    gradient: gradient,
                    color: baseColor,
                  ),
                  AppSpacing.hGapSm,
                  _buildBox(
                    width: 120,
                    height: 14,
                    borderRadius: AppRadius.borderSmall,
                    gradient: gradient,
                    color: baseColor,
                  ),
                  const Spacer(),
                  _buildBox(
                    width: 56,
                    height: 22,
                    borderRadius: AppRadius.borderFull,
                    gradient: gradient,
                    color: baseColor,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBox({
    required double width,
    required double height,
    required BorderRadiusGeometry borderRadius,
    required Color color,
    LinearGradient? gradient,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: borderRadius,
      ),
    );
  }
}
