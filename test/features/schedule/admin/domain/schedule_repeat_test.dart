import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/schedule_repeat.dart';

void main() {
  final start = DateTime(2026, 11, 11); // Wednesday

  test('end date is inclusive', () {
    final days = expandRepeat(start: start, until: DateTime(2026, 11, 13));
    expect(days, [
      DateTime(2026, 11, 11),
      DateTime(2026, 11, 12),
      DateTime(2026, 11, 13),
    ]);
  });

  test('weekly keeps only the chosen weekdays', () {
    final days = expandRepeat(
      start: start,
      until: DateTime(2026, 11, 30),
      weekdays: {DateTime.monday, DateTime.friday},
    );
    expect(days.map((d) => d.day), [13, 16, 20, 23, 27, 30]);
  });

  test('is capped at $maxRepeatDays days after the start', () {
    final days = expandRepeat(start: start, until: DateTime(2030));
    expect(days.length, maxRepeatDays + 1);
    expect(days.last, DateTime(2027, 2, 11));
  });

  test('an end before the start gives nothing', () {
    expect(expandRepeat(start: start, until: DateTime(2026, 11, 10)), isEmpty);
  });

  test('a time of day on the inputs does not shift days', () {
    final days = expandRepeat(
      start: DateTime(2026, 3, 28, 23, 30),
      until: DateTime(2026, 3, 30, 1),
    );
    expect(days.map((d) => d.day), [28, 29, 30]);
  });
}
