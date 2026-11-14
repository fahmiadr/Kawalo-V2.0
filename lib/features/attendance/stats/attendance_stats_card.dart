import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
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
    final tones = KawaloTones.of(context);
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
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ringkasan absensi',
                      style: TextStyle(
                        color: tones.ink2,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AppStatusPill(label: rangeLabel),
                ],
              ),
              const SizedBox(height: 8),
              // Two rows of three slots: five cells in one row squeezed the
              // labels onto two lines.
              _CellRow(cells: cells.sublist(0, 3)),
              const SizedBox(height: 6),
              _CellRow(cells: cells.sublist(3), slots: 3),
            ],
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
    final count = slots ?? cells.length;
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: i < cells.length ? cells[i] : const SizedBox()),
        ],
      ],
    );
  }
}

/// `.stat` cell: a large figure over a small label.
class _Cell extends StatelessWidget {
  const _Cell(this.label, this.value, {this.isAlert = false});

  final String label;
  final String value;

  /// Amber when the count is above zero (late check-ins, early check-outs).
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: tones.surface,
        border: Border.all(color: tones.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: isAlert ? tones.sos.color : tones.ink,
                fontSize: 22,
                fontWeight: FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tones.ink2,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
