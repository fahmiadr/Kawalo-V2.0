import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/schedule/domain/entities/schedule_entity.dart';
import 'package:kawalo_mobile/features/schedule/presentation/extensions/schedule_ui_extension.dart';

ScheduleEntity _shift(
  DateTime date, {
  String start = '08:00',
  String end = '16:00',
}) => ScheduleEntity(
  id: '$date$start',
  date: date,
  shiftName: 'Shift',
  startTime: start,
  endTime: end,
  shiftColor: '#10B981',
);

void main() {
  final now = DateTime(2026, 6, 30, 9, 30);
  final today = DateTime(2026, 6, 30);

  group('nextShiftSubtitle', () {
    test('no schedules', () {
      expect(nextShiftSubtitle(const [], now), 'Belum ada jadwal');
    });

    test('shift still running today', () {
      expect(nextShiftSubtitle([_shift(today)], now), 'Hari ini · 08:00-16:00');
    });

    test('skips a shift that already ended today', () {
      final list = [
        _shift(today, start: '06:00', end: '09:00'),
        _shift(DateTime(2026, 7)),
      ];
      expect(nextShiftSubtitle(list, now), 'Besok · 08:00-16:00');
    });

    test('later day uses a short date', () {
      expect(
        nextShiftSubtitle([_shift(DateTime(2026, 7, 8))], now),
        '8 Jul · 08:00-16:00',
      );
    });

    test('night shift started yesterday is still upcoming until it ends', () {
      final night = _shift(DateTime(2026, 6, 29), start: '22:00', end: '06:00');
      expect(
        nextShiftSubtitle([night], DateTime(2026, 6, 30, 5)),
        '29 Jun · 22:00-06:00',
      );
      expect(
        nextShiftSubtitle([night], DateTime(2026, 6, 30, 7)),
        'Belum ada jadwal',
      );
    });

    test('only past shifts', () {
      expect(
        nextShiftSubtitle([_shift(DateTime(2026, 6, 29))], now),
        'Belum ada jadwal',
      );
    });
  });

  test('relativeDayLabel', () {
    expect(relativeDayLabel(today, now), 'Hari ini');
    expect(relativeDayLabel(DateTime(2026, 7), now), 'Besok');
    expect(relativeDayLabel(DateTime(2026, 7, 2), now), isNull);
  });

  test('shift colour is parsed and purple is dropped', () {
    expect(_shift(today).shiftAccentColor, isNotNull);
    expect(
      ScheduleEntity(
        id: '1',
        date: today,
        shiftName: 'x',
        startTime: '08:00',
        endTime: '16:00',
        shiftColor: '#8B5CF6',
      ).shiftAccentColor,
      isNull,
    );
  });

  test('day label and shift line', () {
    expect(scheduleDayLabel(today, now), 'Hari ini · Sel 30');
    expect(scheduleDayLabel(DateTime(2026, 7, 6), now), 'Sen 6');
    expect(scheduleMonthLabel(today), 'Juni 2026');
    expect(
      ScheduleEntity(
        id: '1',
        date: today,
        shiftName: 'Shift Malam',
        startTime: '23:00',
        endTime: '07:00',
        locationName: 'Pos Utama',
      ).displayShiftLine,
      'Shift Malam · Pos Utama · berakhir besok',
    );
    expect(_shift(today).displayShiftLine, 'Shift');
  });
}
