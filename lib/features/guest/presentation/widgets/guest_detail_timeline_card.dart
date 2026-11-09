import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/presentation/extensions/guest_ui_extension.dart';

/// Kartu linimasa aktivitas kunjungan tamu (Masuk, Konfirmasi, Keluar)
/// dengan standar Material 3 Expressive.
class GuestDetailTimelineCard extends StatelessWidget {
  /// Membuat instance [GuestDetailTimelineCard].
  const GuestDetailTimelineCard({required this.item, super.key});

  /// Data tamu yang ditampilkan.
  final GuestItemEntity item;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final emphasizedScale = theme.typography.emphasized;

    final isConfirmed = item.isConfirmed;
    final isExited = item.isExited;

    return AppCard(
      semanticLabel: 'Log aktivitas kunjungan tamu',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header Kartu Linimasa ───────────────────────────────────────
          Row(
            children: [
              const AppSvgIcon.color(KawaloColorVectors.timeRotation, size: 32),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  'Log aktivitas',
                  style: emphasizedScale.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              AppTag(
                label: isExited ? 'Selesai' : 'Aktif',
                variant: isExited
                    ? AppTagVariant.primary
                    : AppTagVariant.tertiary,
                size: AppTagSize.small,
              ),
            ],
          ),

          AppSpacing.vGap300,

          // ── Linimasa Milestone ──────────────────────────────────────────
          _buildTimelineItem(
            context: context,
            title: 'Masuk',
            timestamp: item.displayEntryTime,
            isActive: true,
            isLineActive: isConfirmed,
            isLast: false,
          ),
          _buildTimelineItem(
            context: context,
            title: 'Konfirmasi',
            timestamp: item.displayConfirmationTime,
            isActive: isConfirmed,
            isLineActive: isExited,
            isLast: false,
          ),
          _buildTimelineItem(
            context: context,
            title: 'Keluar',
            timestamp: item.displayExitTime,
            isActive: isExited,
            isLineActive: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required BuildContext context,
    required String title,
    required String timestamp,
    required bool isActive,
    required bool isLineActive,
    required bool isLast,
  }) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedScale = theme.typography.emphasized;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Node & Garis Penghubung Linimasa ───────────────────────────
          SizedBox(
            width: 36,
            child: Column(
              children: [
                _buildTimelineNode(context, isActive: isActive),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: isLineActive
                          ? Container(width: 2.5, color: colorScheme.primary)
                          : CustomPaint(
                              size: const Size(2, double.infinity),
                              painter: _DashedLinePainter(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
          AppSpacing.hGap200,
          // ── Detail Teks Milestone ───────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppSpacing.space200,
                top: AppSpacing.space50,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: emphasizedScale.titleSmall.copyWith(
                      color: isActive
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.60,
                            ),
                    ),
                  ),
                  AppSpacing.vGap25,
                  Text(
                    timestamp,
                    style: isActive
                        ? typeScale.bodyMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          )
                        : typeScale.bodyMedium.copyWith(
                            color: colorScheme.outline.withValues(alpha: 0.60),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode(BuildContext context, {required bool isActive}) {
    final colorScheme = AppTheme.of(context).colorScheme;

    if (isActive) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.primary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: AppSvgIcon(
          KawaloVectors.checkmarkCircle01Filled,
          size: 18,
          color: colorScheme.primary,
        ),
      );
    }

    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.outlineVariant, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: colorScheme.outlineVariant,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Painter untuk menggambar garis putus-putus pada segmen linimasa tertunda.
class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  static const double _dashHeight = 5;
  static const double _dashSpace = 4;
  static const double _strokeWidth = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    var startY = 0.0;
    final x = size.width / 2;
    while (startY < size.height) {
      final endY = (startY + _dashHeight).clamp(0.0, size.height);
      canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
      startY += _dashHeight + _dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}
