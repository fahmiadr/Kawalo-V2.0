import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/forecast/domain/value_objects/forecast_config.dart';

final _today = DateTime(2026, 11, 12);

ForecastConfig _config({
  DateTime? start,
  DateTime? end,
  Map<String, int> quotas = const {'s1': 1},
  List<String> personnel = const ['a@x.id'],
}) => ForecastConfig(
  startDate: start ?? _today,
  endDate: end ?? DateTime(2026, 11, 18),
  quotas: quotas,
  personnel: personnel,
);

void main() {
  test('rangeDays counts both ends', () {
    expect(_config().rangeDays, 7);
    expect(_config(end: _today).rangeDays, 1);
  });

  test('a valid form has no errors', () {
    expect(_config().validate(_today).isValid, isTrue);
    // Time of day on "today" must not matter.
    expect(_config().validate(DateTime(2026, 11, 12, 23, 59)).isValid, isTrue);
  });

  test('92 days is the longest range', () {
    final end92 = ForecastConfig.addDays(_today, 91);
    expect(_config(end: end92).validate(_today).range, isNull);

    final error = _config(
      end: ForecastConfig.addDays(_today, 92),
    ).validate(_today).range;
    expect(error, 'Rentang 93 hari. Maksimal 92 hari (sampai 11 Feb 2027).');
  });

  test('range rules', () {
    expect(
      _config(end: DateTime(2026, 11, 11)).validate(_today).range,
      'Tanggal selesai tidak boleh sebelum tanggal mulai.',
    );
    expect(
      _config(
        start: DateTime(2026, 11, 11),
        end: DateTime(2026, 11, 13),
      ).validate(_today).range,
      'Tanggal mulai tidak boleh sebelum hari ini.',
    );
    final far = ForecastConfig.addDays(_today, 367);
    expect(
      _config(start: far, end: far).validate(_today).range,
      'Jadwal hanya bisa dibuat sampai 366 hari ke depan.',
    );
    final last = ForecastConfig.addDays(_today, 366);
    expect(_config(start: last, end: last).validate(_today).range, isNull);
  });

  test('needs a shift and a person', () {
    final errors = _config(quotas: {}, personnel: []).validate(_today);
    expect(errors.shifts, 'Pilih minimal satu shift.');
    expect(errors.personnel, 'Pilih minimal satu personil.');
    expect(errors.isValid, isFalse);
  });

  test('caps personnel at 500', () {
    final many = [for (var i = 0; i < 501; i++) 'p$i@x.id'];
    expect(
      _config(personnel: many).validate(_today).personnel,
      'Maksimal 500 personil.',
    );
  });

  test('addDays and dayDiff survive month ends', () {
    expect(ForecastConfig.addDays(DateTime(2026, 12, 31), 1), DateTime(2027));
    expect(
      ForecastConfig.dayDiff(DateTime(2026, 2, 27), DateTime(2026, 3, 2)),
      3,
    );
  });
}
