/// Longest span of the "Ulangi" option, counted from the start date.
const maxRepeatDays = 92;

/// The server rejects schedules further ahead than this.
const maxAheadDays = 366;

/// Most rows one bulk request may carry.
const maxBulkItems = 1000;

/// Days from [start] to [until], both inclusive, capped at [maxRepeatDays]
/// after [start]. [weekdays] (`DateTime.monday`..`sunday`) keeps only those
/// days of the week; `null` means every day.
List<DateTime> expandRepeat({
  required DateTime start,
  required DateTime until,
  Set<int>? weekdays,
}) {
  final first = DateTime(start.year, start.month, start.day);
  final cap = DateTime(first.year, first.month, first.day + maxRepeatDays);
  var last = DateTime(until.year, until.month, until.day);
  if (last.isAfter(cap)) last = cap;
  final days = <DateTime>[];
  // Calendar arithmetic through the constructor so DST never shifts a day.
  for (
    var d = first;
    !d.isAfter(last);
    d = DateTime(d.year, d.month, d.day + 1)
  ) {
    if (weekdays == null || weekdays.contains(d.weekday)) days.add(d);
  }
  return days;
}
