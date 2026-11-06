import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';

/// Skeleton loader untuk kartu absensi dengan shimmer halus
/// sesuai spesifikasi Material 3 Expressive dan menghormati reduced motion.
class AttendanceCardSkeleton extends StatefulWidget {
  /// Membuat instance [AttendanceCardSkeleton].
  const AttendanceCardSkeleton({super.key});

  @override
  State<AttendanceCardSkeleton> createState() => _AttendanceCardSkeletonState();
}

class _AttendanceCardSkeletonState extends State<AttendanceCardSkeleton>
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
              // ── Header: Avatar, Nama, & Email ─────────────────────
              Row(
                children: [
                  _buildBox(
                    width: 40,
                    height: 40,
                    borderRadius: AppRadius.borderSmall,
                    gradient: gradient,
                    color: baseColor,
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBox(
                          width: 140,
                          height: 16,
                          borderRadius: AppRadius.borderSmall,
                          gradient: gradient,
                          color: baseColor,
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

              // ── Tag Status Skeleton ───────────────────────────────
              _buildBox(
                width: 80,
                height: 24,
                borderRadius: AppRadius.borderFull,
                gradient: gradient,
                color: baseColor,
              ),

              // ── Garis Pemisah (AppDivider) ────────────────────────
              const Padding(
                padding: AppSpacing.paddingVertical150,
                child: AppDivider(),
              ),

              // ── Detail Informasi Absensi ──────────────────────────
              _buildDetailRow(
                gradient: gradient,
                baseColor: baseColor,
                textWidth: 140,
              ),
              AppSpacing.vGap50,
              _buildDetailRow(
                gradient: gradient,
                baseColor: baseColor,
                textWidth: 120,
              ),
              AppSpacing.vGap50,
              _buildTimestampAndStatusRow(
                gradient: gradient,
                baseColor: baseColor,
                textWidth: 120,
                tagWidth: 72,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimestampAndStatusRow({
    required Color baseColor,
    required double textWidth,
    required double tagWidth,
    Gradient? gradient,
  }) {
    return Row(
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
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildBox(
              width: textWidth,
              height: 12,
              borderRadius: AppRadius.borderExtraSmall,
              gradient: gradient,
              color: baseColor,
            ),
          ),
        ),
        AppSpacing.hGapSm,
        _buildBox(
          width: tagWidth,
          height: 20,
          borderRadius: AppRadius.borderFull,
          gradient: gradient,
          color: baseColor,
        ),
      ],
    );
  }

  Widget _buildBox({
    required double width,
    required double height,
    required BorderRadiusGeometry borderRadius,
    required Color color,
    Gradient? gradient,
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

  Widget _buildDetailRow({
    required Color baseColor,
    required double textWidth,
    Gradient? gradient,
  }) {
    return Row(
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
          width: textWidth,
          height: 12,
          borderRadius: AppRadius.borderExtraSmall,
          gradient: gradient,
          color: baseColor,
        ),
      ],
    );
  }
}
