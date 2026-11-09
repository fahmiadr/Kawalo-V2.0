import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_card.dart';

/// Skeleton loader untuk kartu informasi ([InformationCard]) dengan animasi
/// shimmer halus yang mengimplementasikan fondasi [AppCard] dan
/// Material 3 Expressive.
class InformationCardSkeleton extends StatefulWidget {
  /// Membuat instance [InformationCardSkeleton].
  const InformationCardSkeleton({
    super.key,
    this.showMedia = false,
    this.showAttachment = false,
  });

  /// Menentukan apakah wadah kolase media foto disertakan pada kartu skeleton.
  final bool showMedia;

  /// Menentukan apakah tag lampiran disertakan pada metadata skeleton.
  final bool showAttachment;

  @override
  State<InformationCardSkeleton> createState() =>
      _InformationCardSkeletonState();
}

class _InformationCardSkeletonState extends State<InformationCardSkeleton>
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
                colors: [baseColor, highlightColor, baseColor],
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
              // ── 1. Header Postingan: Avatar, Penulis & Email ────────
              _buildHeaderSkeleton(gradient, baseColor),

              AppSpacing.vGapSm,

              // ── 2. Tag Kategori, Lampiran, & Waktu Publikasi ────────
              _buildMetaSkeleton(gradient, baseColor),

              AppSpacing.vGapSm,

              // ── 3. Konten Postingan: Judul & Narasi Laporan ─────────
              _buildContentSkeleton(gradient, baseColor),

              // ── 4. Kolase Media Foto (Jika Tersedia) ─────────────────
              if (widget.showMedia) ...[
                AppSpacing.vGapSm,
                _buildMediaSkeleton(gradient, baseColor),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Membangun skeleton header postingan (Avatar 40x40 squircle 12dp, nama,
  /// email).
  Widget _buildHeaderSkeleton(Gradient? gradient, Color baseColor) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppStateLayer.minTouchTarget,
      ),
      child: Row(
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
                _buildBox(
                  width: 140,
                  height: 16,
                  borderRadius: AppRadius.borderExtraSmall,
                  gradient: gradient,
                  color: baseColor,
                ),
                AppSpacing.vGap25,
                _buildBox(
                  width: 180,
                  height: 12,
                  borderRadius: AppRadius.borderExtraSmall,
                  gradient: gradient,
                  color: baseColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun skeleton metadata postingan (Tag kategori, lampiran, ikon
  /// kalender & tanggal).
  Widget _buildMetaSkeleton(Gradient? gradient, Color baseColor) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: AppSpacing.space100,
        runSpacing: AppSpacing.space100,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Wrap(
            spacing: AppSpacing.space100,
            runSpacing: AppSpacing.space50,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildBox(
                width: 72,
                height: 22,
                borderRadius: AppRadius.borderFull,
                gradient: gradient,
                color: baseColor,
              ),
              if (widget.showAttachment)
                _buildBox(
                  width: 84,
                  height: 22,
                  borderRadius: AppRadius.borderFull,
                  gradient: gradient,
                  color: baseColor,
                ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBox(
                width: 14,
                height: 14,
                borderRadius: AppRadius.borderExtraSmall,
                gradient: gradient,
                color: baseColor,
              ),
              AppSpacing.hGapXs,
              _buildBox(
                width: 76,
                height: 12,
                borderRadius: AppRadius.borderExtraSmall,
                gradient: gradient,
                color: baseColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Membangun skeleton judul (2 baris) dan narasi postingan (3 baris).
  Widget _buildContentSkeleton(Gradient? gradient, Color baseColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBox(
          width: double.infinity,
          height: 16,
          borderRadius: AppRadius.borderExtraSmall,
          gradient: gradient,
          color: baseColor,
        ),
        AppSpacing.vGap25,
        _buildBox(
          width: 200,
          height: 16,
          borderRadius: AppRadius.borderExtraSmall,
          gradient: gradient,
          color: baseColor,
        ),
        AppSpacing.vGap25,
        _buildBox(
          width: double.infinity,
          height: 14,
          borderRadius: AppRadius.borderExtraSmall,
          gradient: gradient,
          color: baseColor,
        ),
        AppSpacing.vGap25,
        _buildBox(
          width: double.infinity,
          height: 14,
          borderRadius: AppRadius.borderExtraSmall,
          gradient: gradient,
          color: baseColor,
        ),
        AppSpacing.vGap25,
        _buildBox(
          width: 160,
          height: 14,
          borderRadius: AppRadius.borderExtraSmall,
          gradient: gradient,
          color: baseColor,
        ),
      ],
    );
  }

  /// Membangun skeleton wadah media kolase foto (200dp).
  Widget _buildMediaSkeleton(Gradient? gradient, Color baseColor) {
    return _buildBox(
      width: double.infinity,
      height: 200,
      borderRadius: AppRadius.borderMedium,
      gradient: gradient,
      color: baseColor,
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
}
