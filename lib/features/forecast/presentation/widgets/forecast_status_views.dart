import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/features/forecast/domain/value_objects/forecast_config.dart';
import 'package:kawalo_mobile/features/forecast/presentation/cubit/forecast_state.dart';
import 'package:kawalo_mobile/features/forecast/presentation/widgets/forecast_widgets.dart';

/// Shown while the server computes a plan; there is nothing to act on yet.
class ForecastPreviewLoadingView extends StatelessWidget {
  const ForecastPreviewLoadingView({required this.state, super.key});

  final ForecastPreviewLoading state;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final config = state.config;
    return ForecastContent(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space200),
        child: Align(
          alignment: Alignment.topCenter,
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.space200),
            child: Row(
              children: [
                const AppLoadingIndicator(size: AppLoadingIndicatorSize.small),
                AppSpacing.hGapMd,
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Membuat pratinjau jadwal',
                          style: theme.typography.emphasized.titleSmall
                              .copyWith(color: colorScheme.onSurface),
                        ),
                        Text(
                          'Menghitung ${config.rangeDays} hari, '
                          '${config.quotas.length} shift, '
                          '${config.personnel.length} personil',
                          style: theme.typeScale.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The commit was refused because the data moved on since the preview.
class ForecastStaleView extends StatelessWidget {
  const ForecastStaleView({
    required this.state,
    required this.onRetry,
    required this.onEdit,
    super.key,
  });

  final ForecastStale state;
  final VoidCallback onRetry;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return AppEmptyState(
      icon: Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
      title: 'Pratinjau sudah kedaluwarsa',
      description: '${state.message}\nBelum ada jadwal yang disimpan.',
      action: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTaskButton(
            label: 'Buat Pratinjau Ulang',
            icon: Icons.refresh_rounded,
            tone: KawaloTones.of(context).adm,
            onPressed: onRetry,
          ),
          AppSpacing.vGapSm,
          AppTaskButton(
            label: 'Ubah Pengaturan',
            variant: AppTaskButtonVariant.secondary,
            size: AppTaskButtonSize.medium,
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

/// What was saved: created and deleted rows from the server, the rest from the
/// preview the admin confirmed.
class ForecastSuccessView extends StatelessWidget {
  const ForecastSuccessView({
    required this.state,
    required this.onDone,
    super.key,
  });

  final ForecastApplied state;

  /// "Lihat Jadwal Tim".
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final overwrite = state.config.fillMode == ForecastFillMode.overwrite;
    final missing = state.preview.stats.underStaffedTotal;
    return Column(
      children: [
        Expanded(
          child: ForecastContent(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              children: [
                Center(
                  child: ExcludeSemantics(
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: tones.adm.soft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 52,
                        color: tones.adm.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    '${state.result.created} jadwal dibuat',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: tones.ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${forecastRangeLabel(state.config)}. '
                  'Petugas melihatnya di Jadwal Saya.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: tones.ink2, fontSize: 15),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: tones.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: tones.line),
                  ),
                  child: Column(
                    children: [
                      _ResultRow(
                        label: 'Dibuat',
                        value: '${state.result.created} jadwal',
                        variant: AppTagVariant.primary,
                      ),
                      _ResultRow(
                        label: 'Dihapus',
                        value: '${state.result.deleted} jadwal',
                        variant: AppTagVariant.neutral,
                      ),
                      _ResultRow(
                        label: overwrite
                            ? 'Terkunci, tidak diubah'
                            : 'Dilewati (slot sudah terisi)',
                        value:
                            '${overwrite ? state.preview.lockedCount : state.preview.existingCount} '
                            'jadwal',
                        variant: AppTagVariant.neutral,
                      ),
                      _ResultRow(
                        label: 'Slot belum terisi',
                        value: '$missing slot',
                        variant: missing > 0
                            ? AppTagVariant.error
                            : AppTagVariant.neutral,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ForecastBottomBar(
          buttons: [
            AppTaskButton(
              label: 'Lihat Jadwal Tim',
              tone: tones.adm,
              onPressed: onDone,
            ),
          ],
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    required this.variant,
  });

  final String label;
  final String value;
  final AppTagVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space50),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.typeScale.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          AppTag(label: value, variant: variant, size: AppTagSize.small),
        ],
      ),
    );
  }
}
