import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
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
          AppButton(
            size: AppButtonSize.md,
            onPressed: onRetry,
            child: const Text('Buat Pratinjau Ulang'),
          ),
          AppSpacing.vGapSm,
          AppButton(
            style: AppButtonColor.tonal,
            size: AppButtonSize.md,
            onPressed: onEdit,
            child: const Text('Ubah Pengaturan'),
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
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final overwrite = state.config.fillMode == ForecastFillMode.overwrite;
    final missing = state.preview.stats.underStaffedTotal;
    return Column(
      children: [
        Expanded(
          child: ForecastContent(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.space200),
              children: [
                AppSpacing.vGapXl,
                Center(
                  child: ExcludeSemantics(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 40,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                AppSpacing.vGapMd,
                Semantics(
                  liveRegion: true,
                  child: Text(
                    'Jadwal berhasil dibuat',
                    textAlign: TextAlign.center,
                    style: theme.typography.emphasized.titleLarge.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                AppSpacing.vGap50,
                Text(
                  'Forecast ${forecastRangeLabel(state.config)} tersimpan. '
                  'Petugas bisa melihatnya di menu Jadwal Kerja.',
                  textAlign: TextAlign.center,
                  style: theme.typeScale.bodyMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapLg,
                ClipRRect(
                  borderRadius: AppRadius.borderMedium,
                  child: ColoredBox(
                    color: colorScheme.surfaceContainerHigh,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.space150),
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
                  ),
                ),
              ],
            ),
          ),
        ),
        ForecastBottomBar(
          buttons: [
            AppButton(
              size: AppButtonSize.md,
              onPressed: onDone,
              child: const Text('Selesai'),
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
