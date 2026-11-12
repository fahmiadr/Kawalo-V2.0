import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_slot.dart';

AttendanceSlot slot(
  DateTime date,
  String start,
  String end, {
  String? checkin,
  String? checkout,
}) => AttendanceSlot(
  date: date,
  shiftName: 'Shift',
  startTime: start,
  endTime: end,
  checkin: checkin,
  checkout: checkout,
);

void main() {
  final today = DateTime(2026, 11, 12);
  final yesterday = DateTime(2026, 11, 11);

  test('day shift goes in, then out, then completed', () {
    final now = DateTime(2026, 11, 12, 7, 5);
    final fresh = slot(today, '07:00', '15:00');
    expect(
      planAttendance([fresh], now),
      AttendancePlan.act(fresh, AttendanceAction.checkIn),
    );
    final open = slot(today, '07:00', '15:00', checkin: '07:01:00');
    expect(
      planAttendance([open], now),
      AttendancePlan.act(open, AttendanceAction.checkOut),
    );
    final done = slot(
      today,
      '07:00',
      '15:00',
      checkin: '07:01:00',
      checkout: '15:00:00',
    );
    expect(planAttendance([done], now), AttendancePlan.completed(done));
    expect(planAttendance([], now), const AttendancePlan.noSchedule());
    expect(
      planAttendance([slot(yesterday, '07:00', '15:00')], now),
      const AttendancePlan.noSchedule(),
    );
  });

  test('overnight shift closes on the next day within the window', () {
    final night = slot(yesterday, '22:00', '06:00', checkin: '22:00:00');
    expect(night.endsAt, DateTime(2026, 11, 12, 6));
    expect(
      planAttendance([night], DateTime(2026, 11, 12, 6, 10)).action,
      AttendanceAction.checkOut,
    );
    expect(
      planAttendance([night], DateTime(2026, 11, 12, 18, 1)),
      const AttendancePlan.noSchedule(),
    );
    final morning = slot(today, '06:00', '14:00');
    expect(
      planAttendance([morning, night], DateTime(2026, 11, 12, 6)).slot,
      night,
    );
  });

  test('picks the earliest pending shift', () {
    final late = slot(today, '15:00', '23:00');
    final early = slot(today, '07:00', '15:00');
    expect(
      planAttendance([late, early], DateTime(2026, 11, 12, 6)).slot,
      early,
    );
  });
}
