import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_section_header.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/forecast/domain/entities/forecast_preview.dart';
import 'package:kawalo_mobile/features/forecast/domain/value_objects/forecast_config.dart';
import 'package:kawalo_mobile/features/forecast/presentation/cubit/forecast_cubit.dart';
import 'package:kawalo_mobile/features/forecast/presentation/cubit/forecast_state.dart';
import 'package:kawalo_mobile/features/forecast/presentation/widgets/forecast_widgets.dart';

/// Step 2: statistics ("Ringkasan") and unfilled slots plus the plan per day
/// ("Per hari") of the previewed plan, with the shuffle and save actions.
class ForecastPreviewView extends StatefulWidget {
  const ForecastPreviewView({
    required this.state,
    required this.cubit,
    super.key,
  });

  final ForecastPreviewReady state;
  final ForecastCubit cubit;

  @override
  State<ForecastPreviewView> createState() => _ForecastPreviewViewState();
}

class _ForecastPreviewViewState extends State<ForecastPreviewView> {
  int _tab = 0;

  ForecastPreview get _preview => widget.state.preview;
  ForecastConfig get _config => widget.state.config;

  String? _shiftColor(String uid) {
    for (final s in widget.state.options.shifts) {
      if (s.uid == uid) return s.color;
    }
    return null;
  }

  Future<void> _save() async {
    final cubit = widget.cubit;
    if (_config.fillMode == ForecastFillMode.empty) {
      await cubit.apply();
      return;
    }
    final preview = _preview;
    final locked = preview.lockedCount;
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Timpa ${preview.deleteCount} jadwal?',
      message:
          'Forecast akan menghapus ${preview.deleteCount} jadwal yang belum '
          'terkunci pada ${forecastRangeLabel(_config)}, lalu menyimpan '
          '${preview.stats.totalCreated} jadwal baru.'
          '${locked > 0 ? ' $locked jadwal terkunci tidak diubah.' : ''} '
          'Tindakan ini tidak bisa dibatalkan.',
      confirmText: 'Timpa',
      width: 320,
    );
    if (confirmed ?? false) await cubit.apply(overwriteConfirmed: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final underStaffed = _preview.stats.underStaffedTotal;
    final canSave = _preview.stats.totalCreated > 0;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space200,
            AppSpacing.space100,
            AppSpacing.space200,
            AppSpacing.space100,
          ),
          child: ForecastContent(
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: [
                  const ButtonSegment(value: 0, label: Text('Ringkasan')),
                  ButtonSegment(
                    value: 1,
                    label: Text(
                      underStaffed > 0
                          ? 'Per hari ($underStaffed kosong)'
                          : 'Per hari',
                    ),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
              ),
            ),
          ),
        ),
        Expanded(
          child: ForecastContent(
            child: _tab == 0
                ? _SummaryTab(
                    state: state,
                    shiftColor: _shiftColor,
                    onShowSlots: () => setState(() => _tab = 1),
                  )
                : _DaysTab(state: state, shiftColor: _shiftColor),
          ),
        ),
        ForecastBottomBar(
          message: state.error ?? (canSave ? null : _emptyPlanMessage),
          buttons: [
            AppTaskButton(
              label: 'Terapkan ${_preview.stats.totalCreated} Jadwal',
              icon: Icons.check_rounded,
              tone: KawaloTones.of(context).adm,
              isLoading: state.applying,
              onPressed: state.applying || !canSave
                  ? null
                  : () => unawaited(_save()),
            ),
            if (_tab == 0)
              AppTaskButton(
                label: 'Acak Ulang',
                icon: Icons.refresh_rounded,
                variant: AppTaskButtonVariant.secondary,
                size: AppTaskButtonSize.medium,
                onPressed: state.applying
                    ? null
                    : () => unawaited(widget.cubit.reshuffle()),
              )
            else
              AppTaskButton(
                label: 'Ubah Pengaturan',
                variant: AppTaskButtonVariant.secondary,
                size: AppTaskButtonSize.medium,
                onPressed: state.applying ? null : widget.cubit.backToConfig,
              ),
          ],
        ),
      ],
    );
  }

  static const _emptyPlanMessage =
      'Tidak ada jadwal baru yang bisa dibuat. Ubah pengaturan atau acak ulang.';
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({
    required this.state,
    required this.shiftColor,
    required this.onShowSlots,
  });

  final ForecastPreviewReady state;
  final String? Function(String uid) shiftColor;
  final VoidCallback onShowSlots;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final preview = state.preview;
    final stats = preview.stats;
    final overwrite = state.config.fillMode == ForecastFillMode.overwrite;
    final kept = overwrite ? preview.lockedCount : preview.existingCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space200,
        AppSpacing.space100,
        AppSpacing.space200,
        AppSpacing.space300,
      ),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.space200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${stats.totalCreated} jadwal baru',
                style: theme.typography.emphasized.headlineSmall.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              AppSpacing.vGap50,
              Text(
                '${forecastRangeLabel(state.config)} · ${stats.totalDays} hari '
                '· ${stats.totalPersonnel} personil · ${stats.totalShifts} '
                'shift',
                style: theme.typeScale.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.vGapMd,
              _StackBar(
                segments: [
                  (kept, colorScheme.outline),
                  (stats.totalCreated, colorScheme.primary),
                  (stats.underStaffedTotal, colorScheme.error),
                ],
              ),
              AppSpacing.vGapSm,
              Wrap(
                spacing: AppSpacing.space200,
                runSpacing: AppSpacing.space50,
                children: [
                  _Legend(
                    color: colorScheme.outline,
                    text: '${overwrite ? 'Terkunci' : 'Sudah ada'} $kept',
                  ),
                  _Legend(
                    color: colorScheme.primary,
                    text: 'Baru ${stats.totalCreated}',
                  ),
                  _Legend(
                    color: colorScheme.error,
                    text: 'Kosong ${stats.underStaffedTotal}',
                  ),
                ],
              ),
            ],
          ),
        ),
        if (overwrite) ...[
          AppSpacing.vGapMd,
          _Callout(
            color: colorScheme.errorContainer,
            onColor: colorScheme.onErrorContainer,
            icon: Icons.delete_outline,
            title: '${preview.deleteCount} jadwal lama akan dihapus',
            text: preview.lockedCount > 0
                ? '${preview.lockedCount} jadwal terkunci (sudah lewat atau '
                      'sudah diabsen) dipertahankan.'
                : null,
          ),
        ],
        AppSpacing.vGap300,
        const AppSectionHeader(
          title: 'Terisi per shift',
          subtitle: 'Sudah ada + baru',
          padding: EdgeInsets.zero,
        ),
        AppSpacing.vGapSm,
        for (final s in stats.perShift)
          _BarRow(
            leading: ForecastShiftMarker(color: shiftColor(s.shiftUid)),
            label: s.shiftName,
            value: s.capacity == 0 ? 0 : stats.filledSlots(s) / s.capacity,
            trailing: '${stats.filledSlots(s)}/${s.capacity}',
          ),
        AppSpacing.vGap300,
        AppSectionHeader(
          title: 'Hari kerja per personil',
          subtitle: 'Terendah ${stats.loadMin} · tertinggi ${stats.loadMax}',
          padding: EdgeInsets.zero,
        ),
        AppSpacing.vGapSm,
        for (final p in stats.perPersonnel)
          _BarRow(
            leading: AppUserAvatar(
              name: p.name.isEmpty ? p.email : p.name,
              imageUrl: p.avatarUrl,
              size: 24,
              circle: true,
            ),
            label: p.name.isEmpty ? p.email : p.name,
            value: stats.loadMax == 0 ? 0 : p.total / stats.loadMax,
            trailing: '${p.total} hari',
          ),
        if (stats.underStaffedTotal > 0) ...[
          AppSpacing.vGap300,
          _Callout(
            color: colorScheme.tertiaryContainer,
            onColor: colorScheme.onTertiaryContainer,
            icon: Icons.warning_amber_rounded,
            title: '${stats.underStaffedTotal} slot belum terisi',
            text: 'Aturan istirahat atau jumlah personil.',
            action: AppButton(
              style: AppButtonColor.tonal,
              onPressed: onShowSlots,
              child: const Text('Lihat'),
            ),
          ),
        ],
      ],
    );
  }
}

class _DaysTab extends StatelessWidget {
  const _DaysTab({required this.state, required this.shiftColor});

  final ForecastPreviewReady state;
  final String? Function(String uid) shiftColor;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final stats = state.preview.stats;
    final config = state.config;

    final namesByDayShift = <(DateTime, String), List<String>>{};
    for (final item in state.preview.plan) {
      (namesByDayShift[(item.date, item.shiftUid)] ??= []).add(
        item.name.isEmpty ? item.email : item.name,
      );
    }

    final header = <Widget>[
      if (stats.underStaffed.isNotEmpty) ...[
        AppSectionHeader(
          title: 'Slot belum terisi',
          subtitle:
              '${stats.underStaffedTotal} dari ${stats.totalCapacity} slot',
          padding: EdgeInsets.zero,
        ),
        AppSpacing.vGapSm,
        for (final u in stats.underStaffed) ...[
          _SlotCard(
            slot: u,
            quota: config.quotas[u.shiftUid],
            color: shiftColor(u.shiftUid),
          ),
          AppSpacing.vGapSm,
        ],
        _Suggestions(config: config),
        AppSpacing.vGap300,
      ],
      AppSectionHeader(
        title: 'Jadwal baru per hari',
        subtitle: state.config.fillMode == ForecastFillMode.empty
            ? 'Jadwal yang sudah ada tidak ditampilkan'
            : null,
        padding: EdgeInsets.zero,
      ),
      AppSpacing.vGapSm,
    ];
    final days = config.rangeDays.clamp(0, ForecastConfig.maxRangeDays);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space200,
        AppSpacing.space100,
        AppSpacing.space200,
        AppSpacing.space300,
      ),
      itemCount: header.length + days,
      itemBuilder: (context, i) {
        if (i < header.length) return header[i];
        final day = ForecastConfig.addDays(config.startDate, i - header.length);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space100),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.space150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    AppDateFormat.formatWeekdayDate(day),
                    style: theme.typography.emphasized.titleSmall.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                for (final s in stats.perShift)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.space75),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: ForecastShiftMarker(
                            color: shiftColor(s.shiftUid),
                          ),
                        ),
                        AppSpacing.hGapSm,
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${s.shiftName}: ',
                                  style: theme.typography.emphasized.bodySmall,
                                ),
                                TextSpan(
                                  text:
                                      namesByDayShift[(day, s.shiftUid)]?.join(
                                        ', ',
                                      ) ??
                                      '-',
                                ),
                              ],
                            ),
                            style: theme.typeScale.bodySmall.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.quota,
    required this.color,
  });

  final ForecastUnderStaffed slot;
  final int? quota;
  final String? color;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppDateFormat.formatWeekdayDate(slot.date),
            style: theme.typeScale.labelMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGap50,
          Row(
            children: [
              ForecastShiftMarker(color: color),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  slot.shiftName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.emphasized.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              AppTag(
                label: quota == null
                    ? 'Kurang ${slot.short}'
                    : 'Kurang ${slot.short} dari $quota',
                variant: AppTagVariant.error,
                size: AppTagSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.config});

  final ForecastConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final lines = [
      'Tambah personil, misalnya anggota ADMIN, atau turunkan kuota.',
      if (config.restEnabled &&
          config.maxConsecutive < ForecastConfig.maxConsecutiveLimit)
        'Naikkan batas hari kerja berturut-turut dari ${config.maxConsecutive} ke ${config.maxConsecutive + 1}.',
      'Atau simpan apa adanya dan isi slot kosong dari kalender.',
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space150),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: AppRadius.borderMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saran',
            style: theme.typography.emphasized.titleSmall.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.space50),
              child: Text(
                '• $line',
                style: theme.typeScale.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Proportional bar; zero-sized segments are skipped so no sliver shows.
class _StackBar extends StatelessWidget {
  const _StackBar({required this.segments});

  final List<(int, Color)> segments;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;
    final visible = segments.where((s) => s.$1 > 0).toList();
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: AppRadius.borderFull,
        child: SizedBox(
          height: 10,
          child: visible.isEmpty
              ? ColoredBox(color: colorScheme.surfaceContainerHighest)
              : Row(
                  children: [
                    for (final s in visible)
                      Expanded(
                        flex: s.$1,
                        child: ColoredBox(color: s.$2),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        AppSpacing.hGap50,
        Text(
          text,
          style: theme.typeScale.labelMedium.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.trailing,
    this.leading,
  });

  final Widget? leading;
  final String label;

  /// 0..1.
  final double value;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    return Semantics(
      container: true,
      label: '$label: $trailing',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space50),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Row(
                children: [
                  if (leading != null) ...[leading!, AppSpacing.hGapSm],
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typeScale.bodySmall.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: ClipRRect(
                borderRadius: AppRadius.borderFull,
                child: LinearProgressIndicator(
                  value: value.clamp(0, 1),
                  minHeight: 8,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            AppSpacing.hGapSm,
            SizedBox(
              width: 56,
              child: Text(
                trailing,
                textAlign: TextAlign.end,
                style: theme.typeScale.labelMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({
    required this.color,
    required this.onColor,
    required this.icon,
    required this.title,
    this.text,
    this.action,
  });

  final Color color;
  final Color onColor;
  final IconData icon;
  final String title;
  final String? text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space150),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.borderMedium,
      ),
      child: Row(
        children: [
          Icon(icon, color: onColor),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.typography.emphasized.titleSmall.copyWith(
                    color: onColor,
                  ),
                ),
                if (text != null)
                  Text(
                    text!,
                    style: theme.typeScale.bodySmall.copyWith(color: onColor),
                  ),
              ],
            ),
          ),
          if (action != null) ...[AppSpacing.hGapSm, action!],
        ],
      ),
    );
  }
}
