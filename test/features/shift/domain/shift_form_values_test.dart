import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_clock.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_form_values.dart';

const _pagi = ShiftClock(7, 0);
const _sore = ShiftClock(15, 0);

ShiftFormValues _valid() =>
    const ShiftFormValues(name: 'Shift Pagi', startTime: _pagi, endTime: _sore);

void main() {
  group('ShiftClock', () {
    test('parses strict HH:MM only', () {
      expect(ShiftClock.tryParse('07:05'), const ShiftClock(7, 5));
      expect(ShiftClock.tryParse('23:59'), const ShiftClock(23, 59));
      for (final bad in ['24:00', '7:00', '07:60', '07-00', '0700', '', null]) {
        expect(ShiftClock.tryParse(bad), isNull, reason: '$bad');
      }
    });

    test('prints zero padded', () {
      expect(const ShiftClock(7, 5).toString(), '07:05');
    });

    test('duration wraps past midnight and treats equal clocks as a day', () {
      expect(_pagi.minutesUntil(_sore), 480);
      expect(_pagi.endsNextDay(_sore), isFalse);
      const night = ShiftClock(22, 0);
      const morning = ShiftClock(6, 0);
      expect(night.minutesUntil(morning), 480);
      expect(night.endsNextDay(morning), isTrue);
      expect(_pagi.minutesUntil(_pagi), 1440);
    });
  });

  group('ShiftFormValues.validate', () {
    test('a minimal shift is valid', () {
      expect(_valid().validate().isValid, isTrue);
    });

    test('requires a name, within 128 characters', () {
      expect(
        _valid().copyWith(name: '   ').validate().name,
        'Nama shift wajib diisi.',
      );
      expect(
        _valid().copyWith(name: 'a' * 129).validate().name,
        'Nama shift maksimal 128 karakter.',
      );
      expect(_valid().copyWith(name: 'a' * 128).validate().name, isNull);
    });

    test('requires both times and rejects equal ones', () {
      const empty = ShiftFormValues(name: 'x');
      expect(empty.validate().startTime, 'Pilih jam mulai.');
      expect(empty.validate().endTime, 'Pilih jam selesai.');
      expect(
        _valid().copyWith(endTime: _pagi).validate().endTime,
        'Jam mulai dan jam selesai tidak boleh sama.',
      );
    });

    test('a shift ending before it starts is valid (overnight)', () {
      final values = _valid().copyWith(
        startTime: const ShiftClock(22, 0),
        endTime: const ShiftClock(6, 0),
      );
      expect(values.validate().isValid, isTrue);
    });

    test('the description is at most 128 characters', () {
      expect(
        _valid().copyWith(description: 'a' * 129).validate().description,
        'Deskripsi maksimal 128 karakter.',
      );
      expect(
        _valid().copyWith(description: 'a' * 128).validate().description,
        isNull,
      );
    });
  });

  group('ShiftFormValues.toInput', () {
    test('trims the text and drops a blank description', () {
      final input = _valid()
          .copyWith(name: ' Shift Pagi ', description: '  ')
          .toInput();
      expect(input.name, 'Shift Pagi');
      expect(input.description, isNull);
    });

    test('carries an uppercase colour and the description', () {
      final input = _valid()
          .copyWith(color: '#f2a900', description: ' Keliling ')
          .toInput();
      expect(input.color, '#F2A900');
      expect(input.description, 'Keliling');
    });
  });
}
