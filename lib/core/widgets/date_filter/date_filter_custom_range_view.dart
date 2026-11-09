import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/date_filter/date_filter_date_card.dart';

/// Tampilan atur rentang waktu kustom (Dari, Ke, Pasang) pada
/// `AppDateFilterBottomSheet`.
class DateFilterCustomRangeView extends StatelessWidget {
  const DateFilterCustomRangeView({
    required this.draftStartDate,
    required this.draftEndDate,
    required this.canConfirm,
    required this.onBack,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onConfirm,
    this.errorMessage,
    super.key,
  });

  final DateTime? draftStartDate;
  final DateTime? draftEndDate;
  final String? errorMessage;
  final bool canConfirm;
  final VoidCallback onBack;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasized = theme.typography.emphasized;

    return SingleChildScrollView(
      key: const ValueKey('filter_custom_range_view'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: Tombol Kembali + Judul ──────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space150,
            ),
            child: Row(
              children: [
                AppIconButton(
                  icon: const AppSvgIcon(KawaloVectors.arrowLeft02, size: 28),
                  onPressed: onBack,
                  semanticLabel: 'Kembali ke opsi rentang waktu',
                ),
                Expanded(
                  child: Text(
                    'Atur rentang waktu',
                    style: emphasized.titleLarge.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          AppSpacing.vGapSm,

          // ── Content: 24dp horizontal padding ──────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space300,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Dua Kartu Input Tanggal ────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: DateFilterDateCard(
                        label: 'Dari',
                        date: draftStartDate,
                        onTap: onPickStartDate,
                      ),
                    ),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: DateFilterDateCard(
                        label: 'Ke',
                        date: draftEndDate,
                        onTap: onPickEndDate,
                      ),
                    ),
                  ],
                ),

                if (errorMessage != null) ...[
                  AppSpacing.vGap50,
                  Text(
                    errorMessage!,
                    style: typeScale.labelSmall.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ],

                AppSpacing.vGap300,

                // ── Tombol Pasang ──────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    shape: AppButtonShape.square,
                    size: AppButtonSize.md,
                    enabled: canConfirm,
                    onPressed: canConfirm ? onConfirm : null,
                    semanticLabel: 'Pasang rentang waktu',
                    child: Text('Pasang', style: typeScale.titleMedium),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
