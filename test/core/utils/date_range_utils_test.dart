import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/utils/date_range_utils.dart';

enum TestPeriod { today, thisWeek, thisMonth, custom }

void main() {
  group('DateRangeUtils Tests', () {
    final fixedNow = DateTime(2026, 9, 9, 14, 30); // Rabu, 9 Sep 2026

    test('resolves today period correctly', () {
      final (start, end) = DateRangeUtils.resolve(
        TestPeriod.today,
        referenceNow: fixedNow,
      );

      expect(start, DateTime(2026, 9, 9));
      expect(end, DateTime(2026, 9, 9, 23, 59, 59));
    });

    test('resolves thisWeek period correctly', () {
      // 9 Sep 2026 is Wednesday (weekday 3). Senin is 7 Sep 2026,
      // Minggu is 13 Sep 2026.
      final (start, end) = DateRangeUtils.resolve(
        TestPeriod.thisWeek,
        referenceNow: fixedNow,
      );

      expect(start, DateTime(2026, 9, 7));
      expect(end, DateTime(2026, 9, 13, 23, 59, 59));
    });

    test('resolves thisMonth period correctly', () {
      final (start, end) = DateRangeUtils.resolve(
        TestPeriod.thisMonth,
        referenceNow: fixedNow,
      );

      expect(start, DateTime(2026, 9));
      expect(end, DateTime(2026, 9, 30, 23, 59, 59));
    });

    test('resolves custom period correctly', () {
      final customStart = DateTime(2026, 8);
      final customEnd = DateTime(2026, 8, 15);

      final (start, end) = DateRangeUtils.resolve(
        TestPeriod.custom,
        customStart: customStart,
        customEnd: customEnd,
        referenceNow: fixedNow,
      );

      expect(start, customStart);
      expect(end, customEnd);
    });
  });
}
