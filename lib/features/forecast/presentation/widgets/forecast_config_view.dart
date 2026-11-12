import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_date_picker.dart';
import 'package:kawalo_mobile/core/widgets/app_section_header.dart';
import 'package:kawalo_mobile/features/forecast/domain/entities/forecast_options.dart';
import 'package:kawalo_mobile/features/forecast/domain/value_objects/forecast_config.dart';
import 'package:kawalo_mobile/features/forecast/presentation/cubit/forecast_cubit.dart';
import 'package:kawalo_mobile/features/forecast/presentation/cubit/forecast_state.dart';
import 'package:kawalo_mobile/features/forecast/presentation/screens/forecast_personnel_screen.dart';
import 'package:kawalo_mobile/features/forecast/presentation/widgets/forecast_widgets.dart';

/// Step 1: range, shifts with quota, personnel, rest rule and fill mode.
class ForecastConfigView extends StatelessWidget {
  const ForecastConfigView({
    required this.state,
    required this.cubit,
    super.key,
  });

  static const _presets = [3, 7, 14, 30];

  final ForecastConfiguring state;
  final ForecastCubit cubit;

  @override
  Widget build(BuildContext context) {
    final config = state.config;
    final errors = config.validate(cubit.today);
    // A bad range is the direct result of picking dates, so it shows at once;
    // the other sections only complain after a failed attempt to continue.
    final rangeError = errors.range;
    final shiftsError = state.showErrors ? errors.shifts : null;
    final personnelError = state.showErrors ? errors.personnel : null;
    final blocked = rangeError != null || (state.showErrors && !errors.isValid);

    return Column(
      children: [
        Expanded(
          child: ForecastContent(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space200,
                AppSpacing.space100,
                AppSpacing.space200,
                AppSpacing.space300,
              ),
              children: [
                _RangeSection(config: config, error: rangeError, cubit: cubit),
                AppSpacing.vGap300,
                _ShiftSection(
                  options: state.options,
                  config: config,
                  error: shiftsError,
                  cubit: cubit,
                ),
                AppSpacing.vGap300,
                _PersonnelSection(
                  options: state.options,
                  config: config,
                  error: personnelError,
                  cubit: cubit,
                ),
                AppSpacing.vGap300,
                _RestSection(config: config, cubit: cubit),
                AppSpacing.vGap300,
                _FillModeSection(config: config, cubit: cubit),
              ],
            ),
          ),
        ),
        ForecastBottomBar(
          message: state.error,
          buttons: [
            AppButton(
              size: AppButtonSize.md,
              onPressed: blocked
                  ? null
                  : () => unawaited(cubit.requestPreview()),
              child: const Text('Lihat Pratinjau'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text, {this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space75),
      child: Semantics(
        liveRegion: isError,
        child: Text(
          text,
          style: theme.typeScale.bodySmall.copyWith(
            color: isError
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _RangeSection extends StatelessWidget {
  const _RangeSection({
    required this.config,
    required this.error,
    required this.cubit,
  });

  final ForecastConfig config;
  final String? error;
  final ForecastCubit cubit;

  Future<void> _pick(BuildContext context, {required bool isStart}) async {
    final today = cubit.today;
    final picked = await showAppDatePicker(
      context: context,
      firstDate: isStart ? today : config.startDate,
      lastDate: ForecastConfig.addDays(today, ForecastConfig.maxDaysAhead),
      initialDate: isStart ? config.startDate : config.endDate,
      helpText: isStart ? 'Tanggal mulai' : 'Tanggal selesai',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked == null) return;
    if (isStart) {
      cubit.setStartDate(picked);
    } else {
      cubit.setEndDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = config.rangeDays;
    final preset = ForecastConfigView._presets.contains(days) ? days : null;
    final validRange = !config.endDate.isBefore(config.startDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'Rentang tanggal'),
        AppSpacing.vGapSm,
        Wrap(
          spacing: AppSpacing.space100,
          runSpacing: AppSpacing.space50,
          children: [
            for (final p in ForecastConfigView._presets)
              ChoiceChip(
                label: Text('$p hari'),
                selected: preset == p,
                onSelected: (_) => cubit.setRangeDays(p),
              ),
            ChoiceChip(
              label: const Text('Kustom'),
              selected: preset == null,
              onSelected: (_) => unawaited(_pick(context, isStart: false)),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: 'Mulai',
                date: config.startDate,
                onTap: () => unawaited(_pick(context, isStart: true)),
              ),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: _DateField(
                label: 'Selesai',
                date: config.endDate,
                isError: error != null,
                onTap: () => unawaited(_pick(context, isStart: false)),
              ),
            ),
          ],
        ),
        if (error != null)
          _Hint(error!, isError: true)
        else if (validRange)
          _Hint(
            '$days hari (${forecastWeekdayShort(config.startDate)} - '
            '${forecastWeekdayShort(config.endDate)}). '
            'Maksimal ${ForecastConfig.maxRangeDays} hari.',
          ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
    this.isError = false,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final text = AppDateFormat.formatDateOnly(date);
    return Semantics(
      button: true,
      label: 'Tanggal $label, $text',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderMedium,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space150,
            vertical: AppSpacing.space75,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderMedium,
            border: Border.all(
              color: isError ? colorScheme.error : colorScheme.outline,
              width: isError ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.typeScale.labelSmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      text,
                      style: theme.typeScale.bodyMedium.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShiftSection extends StatelessWidget {
  const _ShiftSection({
    required this.options,
    required this.config,
    required this.error,
    required this.cubit,
  });

  final ForecastOptions options;
  final ForecastConfig config;
  final String? error;
  final ForecastCubit cubit;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Shift dan kuota',
          subtitle: 'Jumlah orang per hari',
        ),
        AppSpacing.vGapSm,
        if (options.shifts.isEmpty)
          Text(
            'Grup ini belum punya shift. Buat shift lebih dulu.',
            style: theme.typeScale.bodyMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (final shift in options.shifts)
            _ShiftRow(
              shift: shift,
              quota: config.quotas[shift.uid],
              cubit: cubit,
            ),
        if (error != null) _Hint(error!, isError: true),
      ],
    );
  }
}

class _ShiftRow extends StatelessWidget {
  const _ShiftRow({
    required this.shift,
    required this.quota,
    required this.cubit,
  });

  final ForecastShift shift;

  /// `null` when the shift is not selected.
  final int? quota;
  final ForecastCubit cubit;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final selected = quota != null;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            semanticLabel: 'Pilih shift ${shift.name}',
            onChanged: (_) => cubit.toggleShift(shift.uid),
          ),
          ForecastShiftMarker(color: shift.color),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  shift.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.emphasized.titleSmall.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${shift.startTime}-${shift.endTime}',
                  style: theme.typeScale.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ForecastStepper(
            value: quota ?? 1,
            min: 1,
            max: ForecastConfig.maxQuota,
            label: 'kuota shift ${shift.name}',
            onChanged: selected ? (v) => cubit.setQuota(shift.uid, v) : null,
          ),
        ],
      ),
    );
  }
}

class _PersonnelSection extends StatelessWidget {
  const _PersonnelSection({
    required this.options,
    required this.config,
    required this.error,
    required this.cubit,
  });

  final ForecastOptions options;
  final ForecastConfig config;
  final String? error;
  final ForecastCubit cubit;

  Future<void> _open(BuildContext context) async {
    final picked = await Navigator.of(context).push(
      ForecastPersonnelScreen.route(
        people: options.people,
        selected: config.personnel,
      ),
    );
    if (picked != null) cubit.setPersonnel(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = config.personnel.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'Personil'),
        AppSpacing.vGapSm,
        AppCard(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space150,
            AppSpacing.space100,
            AppSpacing.space100,
            AppSpacing.space100,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$selected dari ${options.people.length} anggota dipilih',
                      style: theme.typography.emphasized.titleSmall.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      error ?? 'Petugas (GUARD) terpilih otomatis',
                      style: theme.typeScale.bodySmall.copyWith(
                        color: error == null
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.hGapSm,
              AppButton(
                style: AppButtonColor.tonal,
                onPressed: () => unawaited(_open(context)),
                child: const Text('Pilih'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RestSection extends StatelessWidget {
  const _RestSection({required this.config, required this.cubit});

  final ForecastConfig config;
  final ForecastCubit cubit;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'Aturan istirahat'),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space50,
          ),
          title: const Text('Sisakan hari libur'),
          value: config.restEnabled,
          onChanged: (v) => cubit.setRestEnabled(enabled: v),
        ),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.space50),
                child: Text(
                  'Maks. hari kerja berturut-turut',
                  style: theme.typeScale.bodyMedium.copyWith(
                    color: config.restEnabled
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
              ),
            ),
            ForecastStepper(
              value: config.maxConsecutive,
              min: 1,
              max: ForecastConfig.maxConsecutiveLimit,
              label: 'maksimal hari kerja berturut-turut',
              onChanged: config.restEnabled ? cubit.setMaxConsecutive : null,
            ),
          ],
        ),
        const _Hint('Shift Malam lalu Pagi keesokan harinya selalu dihindari.'),
      ],
    );
  }
}

class _FillModeSection extends StatelessWidget {
  const _FillModeSection({required this.config, required this.cubit});

  final ForecastConfig config;
  final ForecastCubit cubit;

  @override
  Widget build(BuildContext context) {
    final overwrite = config.fillMode == ForecastFillMode.overwrite;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'Mode isi'),
        AppSpacing.vGapSm,
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ForecastFillMode>(
            segments: const [
              ButtonSegment(
                value: ForecastFillMode.empty,
                label: Text('Hanya slot kosong'),
              ),
              ButtonSegment(
                value: ForecastFillMode.overwrite,
                label: Text('Timpa jadwal'),
              ),
            ],
            selected: {config.fillMode},
            onSelectionChanged: (s) => cubit.setFillMode(s.first),
          ),
        ),
        _Hint(
          overwrite
              ? 'Jadwal yang belum terkunci pada rentang ini dihapus lalu '
                    'dibuat ulang. Jadwal yang sudah lewat atau sudah diabsen '
                    'tidak diubah.'
              : 'Jadwal yang sudah ada dipertahankan; hanya slot kosong yang '
                    'diisi.',
        ),
      ],
    );
  }
}
