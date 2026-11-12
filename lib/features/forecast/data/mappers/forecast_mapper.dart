import 'package:kawalo_mobile/features/forecast/data/models/forecast_option_models.dart';
import 'package:kawalo_mobile/features/forecast/data/models/forecast_preview_model.dart';
import 'package:kawalo_mobile/features/forecast/domain/entities/forecast_options.dart';
import 'package:kawalo_mobile/features/forecast/domain/entities/forecast_preview.dart';

/// Local midnight of a `YYYY-MM-DD` string; the epoch day for malformed input
/// so one bad row cannot break the whole preview.
DateTime _day(String raw) {
  final parsed = DateTime.tryParse(raw);
  return parsed == null
      ? DateTime(1970)
      : DateTime(parsed.year, parsed.month, parsed.day);
}

abstract final class ForecastMapper {
  const ForecastMapper._();

  /// Rows without a uid or email cannot be selected, so they are dropped.
  static ForecastOptions toOptions(
    List<ForecastShiftModel> shifts,
    List<ForecastMemberModel> members,
  ) => ForecastOptions(
    shifts: [
      for (final s in shifts)
        if (s.uid.isNotEmpty)
          ForecastShift(
            uid: s.uid,
            name: s.name,
            startTime: s.startTime,
            endTime: s.endTime,
            color: s.color,
          ),
    ],
    people: [
      for (final m in members)
        if (m.email.isNotEmpty)
          ForecastPerson(
            email: m.email,
            name: m.name,
            role: m.role.trim().toUpperCase(),
            avatarUrl: m.avatarUrl,
          ),
    ],
  );

  static ForecastPreview toPreview(ForecastPreviewModel m) => ForecastPreview(
    seed: m.seed,
    token: m.token,
    existingCount: m.existingCount,
    deleteCount: m.deleteCount,
    lockedCount: m.lockedCount,
    plan: [
      for (final p in m.plan)
        ForecastPlanItem(
          date: _day(p.date),
          shiftUid: p.shiftUid,
          email: p.email,
          name: p.name,
        ),
    ],
    stats: ForecastStats(
      totalCreated: m.stats.totalCreated,
      totalDays: m.stats.totalDays,
      totalPersonnel: m.stats.totalPersonnel,
      totalShifts: m.stats.totalShifts,
      totalCapacity: m.stats.totalCapacity,
      perShift: [
        for (final s in m.stats.perShift)
          ForecastShiftStat(
            shiftUid: s.shiftUid,
            shiftName: s.shiftName,
            created: s.created,
            capacity: s.capacity,
          ),
      ],
      perPersonnel: [
        for (final p in m.stats.perPersonnel)
          ForecastPersonStat(
            email: p.email,
            name: p.name,
            total: p.total,
            avatarUrl: p.avatarUrl,
          ),
      ],
      loadMin: m.stats.loadMin,
      loadMax: m.stats.loadMax,
      underStaffed: [
        for (final u in m.stats.underStaffed)
          ForecastUnderStaffed(
            date: _day(u.date),
            shiftUid: u.shiftUid,
            shiftName: u.shiftName,
            short: u.short,
          ),
      ],
      underStaffedTotal: m.stats.underStaffedTotal,
    ),
  );

  static ForecastResult toResult(ForecastResultModel m) =>
      ForecastResult(created: m.created, deleted: m.deleted);
}
