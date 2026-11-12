import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/attendance/stats/attendance_stats.dart';
import 'package:kawalo_mobile/features/attendance/stats/attendance_stats_cubit.dart';

/// Summary card shown above the attendance list. It hides itself when the
/// summary could not be loaded: the list below still works on its own.
class AttendanceStatsCard extends StatelessWidget {
  const AttendanceStatsCard({
    required this.cubit,
    required this.rangeLabel,
    super.key,
  });

  final AttendanceStatsCubit cubit;

  /// Label of the active date filter, for example "Hari ini".
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceStatsCubit, AttendanceStatsState>(
      bloc: cubit,
      builder: (context, state) {
        if (state.status == AttendanceStatsStatus.failure) {
          return const SizedBox.shrink();
        }
        return _Card(stats: state.stats, rangeLabel: rangeLabel);
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.stats, required this.rangeLabel});

  final AttendanceStats? stats;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final emphasized = theme.typography.emphasized;
    final stats = this.stats;

    String value(int? n) => n?.toString() ?? '–';
    final cells = [
      _Cell('Total', value(stats?.total)),
      _Cell('Masuk', value(stats?.checkIn)),
      _Cell('Pulang', value(stats?.checkOut)),
      _Cell('Terlambat', value(stats?.late), isAlert: (stats?.late ?? 0) > 0),
      _Cell(
        'Pulang cepat',
        value(stats?.earlyLeave),
        isAlert: (stats?.earlyLeave ?? 0) > 0,
      ),
    ];

    return Semantics(
      container: true,
      label:
          'Ringkasan absensi $rangeLabel: ${cells.map((c) => '${c.label} ${c.value}').join(', ')}',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: AppRadius.borderLarge,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space200,
              vertical: AppSpacing.space150,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ringkasan absensi',
                        style: emphasized.titleMedium.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    AppSpacing.hGapSm,
                    AppTag(
                      label: rangeLabel,
                      variant: AppTagVariant.neutral,
                      size: AppTagSize.small,
                    ),
                  ],
                ),
                AppSpacing.vGapSm,
                // Two rows of three slots: five cells in one row squeezed the
                // labels onto two lines.
                _CellRow(cells: cells.sublist(0, 3)),
                AppSpacing.vGapSm,
                _CellRow(cells: cells.sublist(3), slots: 3),
                AppSpacing.vGapSm,
                Text(
                  'Dihitung dari seluruh data pada rentang tanggal, bukan '
                  'hanya yang termuat.',
                  style: theme.typeScale.labelMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
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

class _CellRow extends StatelessWidget {
  const _CellRow({required this.cells, this.slots});

  final List<_Cell> cells;

  /// Total slots in the row; unused ones stay empty so columns line up with
  /// the row above.
  final int? slots;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;
    final count = slots ?? cells.length;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0)
              VerticalDivider(
                width: AppSpacing.space200,
                color: i < cells.length
                    ? colorScheme.outlineVariant
                    : Colors.transparent,
              ),
            Expanded(child: i < cells.length ? cells[i] : const SizedBox()),
          ],
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.label, this.value, {this.isAlert = false});

  final String label;
  final String value;

  /// Red when the count is above zero (late check-ins, early check-outs).
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: theme.typography.emphasized.titleLarge.copyWith(
              color: isAlert ? colorScheme.error : colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          label,
          style: theme.typeScale.labelSmall.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
