import 'package:equatable/equatable.dart';

class ForecastPlanItem extends Equatable {
  const ForecastPlanItem({
    required this.date,
    required this.shiftUid,
    required this.email,
    required this.name,
  });

  /// Calendar day at local midnight.
  final DateTime date;
  final String shiftUid;
  final String email;
  final String name;

  @override
  List<Object?> get props => [date, shiftUid, email, name];
}

class ForecastShiftStat extends Equatable {
  const ForecastShiftStat({
    required this.shiftUid,
    required this.shiftName,
    required this.created,
    required this.capacity,
  });

  final String shiftUid;
  final String shiftName;

  /// Rows the plan adds; rows that already exist are not counted here.
  final int created;

  /// Quota times the number of days.
  final int capacity;

  @override
  List<Object?> get props => [shiftUid, shiftName, created, capacity];
}

class ForecastPersonStat extends Equatable {
  const ForecastPersonStat({
    required this.email,
    required this.name,
    required this.total,
    this.avatarUrl,
  });

  final String email;
  final String name;
  final String? avatarUrl;

  /// Workdays in the range, including the ones that already exist when the
  /// mode is "empty".
  final int total;

  @override
  List<Object?> get props => [email, name, total, avatarUrl];
}

class ForecastUnderStaffed extends Equatable {
  const ForecastUnderStaffed({
    required this.date,
    required this.shiftUid,
    required this.shiftName,
    required this.short,
  });

  final DateTime date;
  final String shiftUid;
  final String shiftName;
  final int short;

  @override
  List<Object?> get props => [date, shiftUid, shiftName, short];
}

class ForecastStats extends Equatable {
  const ForecastStats({
    required this.totalCreated,
    required this.totalDays,
    required this.totalPersonnel,
    required this.totalShifts,
    required this.totalCapacity,
    required this.perShift,
    required this.perPersonnel,
    required this.loadMin,
    required this.loadMax,
    required this.underStaffed,
    required this.underStaffedTotal,
  });

  final int totalCreated;
  final int totalDays;
  final int totalPersonnel;
  final int totalShifts;
  final int totalCapacity;
  final List<ForecastShiftStat> perShift;
  final List<ForecastPersonStat> perPersonnel;
  final int loadMin;
  final int loadMax;
  final List<ForecastUnderStaffed> underStaffed;
  final int underStaffedTotal;

  /// Slots of the shift in [stat] that reach their quota once the plan is saved. The
  /// server only counts new rows per shift, so existing ones are derived from
  /// what is still missing.
  int filledSlots(ForecastShiftStat stat) {
    final missing = underStaffed
        .where((u) => u.shiftUid == stat.shiftUid)
        .fold<int>(0, (sum, u) => sum + u.short);
    return (stat.capacity - missing).clamp(0, stat.capacity);
  }

  @override
  List<Object?> get props => [
    totalCreated,
    totalDays,
    totalPersonnel,
    totalShifts,
    totalCapacity,
    perShift,
    perPersonnel,
    loadMin,
    loadMax,
    underStaffed,
    underStaffedTotal,
  ];
}

/// Dry run of `POST /schedules/generate/preview`. [seed] and [token] must be
/// echoed back unchanged on commit; the server recomputes the plan from them.
class ForecastPreview extends Equatable {
  const ForecastPreview({
    required this.seed,
    required this.token,
    required this.existingCount,
    required this.deleteCount,
    required this.lockedCount,
    required this.plan,
    required this.stats,
  });

  final int seed;
  final String token;

  /// Schedules of the group already inside the range.
  final int existingCount;

  /// Rows the "overwrite" mode removes (unlocked ones only).
  final int deleteCount;

  /// Past or already checked-in rows that are never touched.
  final int lockedCount;

  final List<ForecastPlanItem> plan;
  final ForecastStats stats;

  @override
  List<Object?> get props => [
    seed,
    token,
    existingCount,
    deleteCount,
    lockedCount,
    plan,
    stats,
  ];
}

class ForecastResult extends Equatable {
  const ForecastResult({required this.created, required this.deleted});

  final int created;
  final int deleted;

  @override
  List<Object?> get props => [created, deleted];
}
