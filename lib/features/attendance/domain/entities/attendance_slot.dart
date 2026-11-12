import 'package:equatable/equatable.dart';

/// One shift of the signed-in user from `GET /schedules/me`, with the
/// check-in/out clock times the attendance flow needs.
class AttendanceSlot extends Equatable {
  const AttendanceSlot({
    required this.date,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    this.locationName,
    this.checkin,
    this.checkout,
  });

  /// Local midnight of the shift day.
  final DateTime date;
  final String shiftName;

  /// `HH:MM`.
  final String startTime;
  final String endTime;
  final String? locationName;

  /// Clock times (`HH:MM:SS`) or null.
  final String? checkin;
  final String? checkout;

  bool get checkedIn => checkin != null;
  bool get checkedOut => checkout != null;

  /// An end at or before the start means the shift ends the next day.
  bool get overnight => _minutes(endTime) <= _minutes(startTime);

  DateTime get startsAt => _at(date, startTime);

  DateTime get endsAt {
    final end = _at(date, endTime);
    return overnight
        ? DateTime(end.year, end.month, end.day + 1, end.hour, end.minute)
        : end;
  }

  String get timeWindow => '$startTime - $endTime';

  static int _minutes(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts.first) ?? 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return h * 60 + m;
  }

  static DateTime _at(DateTime day, String hhmm) {
    final minutes = _minutes(hhmm);
    return DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);
  }

  @override
  List<Object?> get props => [
    date,
    shiftName,
    startTime,
    endTime,
    locationName,
    checkin,
    checkout,
  ];
}

enum AttendanceAction { checkIn, checkOut }

/// What the server will most likely do, so the screen can label the button.
/// The server decides again on submit; this is only a forecast.
class AttendancePlan extends Equatable {
  const AttendancePlan._(this.slot, this.action);

  const AttendancePlan.act(AttendanceSlot slot, AttendanceAction action)
    : this._(slot, action);

  const AttendancePlan.completed(AttendanceSlot slot) : this._(slot, null);

  const AttendancePlan.noSchedule() : this._(null, null);

  final AttendanceSlot? slot;

  /// Null when there is nothing left to do ([slot] set: done for today).
  final AttendanceAction? action;

  @override
  List<Object?> get props => [slot, action];
}

/// How long after its end yesterday's overnight shift can still be checked
/// out. Mirrors `OVERNIGHT_CHECKOUT_WINDOW` in the API's `rules.rs`.
const Duration overnightCheckoutWindow = Duration(hours: 12);

/// Port of the API's `rules::decide` over today's and yesterday's [slots]:
/// an open shift is checked out first, else the earliest shift not checked
/// in, else completed (today had a shift) or no schedule.
AttendancePlan planAttendance(List<AttendanceSlot> slots, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  bool isToday(AttendanceSlot s) => s.date == today;
  bool lastNight(AttendanceSlot s) => s.date == yesterday && s.overnight;

  for (final s in slots) {
    if (s.checkedIn &&
        !s.checkedOut &&
        (isToday(s) ||
            (lastNight(s) &&
                !now.isAfter(s.endsAt.add(overnightCheckoutWindow))))) {
      return AttendancePlan.act(s, AttendanceAction.checkOut);
    }
  }
  final pending =
      slots
          .where(
            (s) =>
                !s.checkedIn &&
                (isToday(s) || (lastNight(s) && now.isBefore(s.endsAt))),
          )
          .toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  if (pending.isNotEmpty) {
    return AttendancePlan.act(pending.first, AttendanceAction.checkIn);
  }
  final todays = slots.where(isToday);
  return todays.isEmpty
      ? const AttendancePlan.noSchedule()
      : AttendancePlan.completed(todays.last);
}
