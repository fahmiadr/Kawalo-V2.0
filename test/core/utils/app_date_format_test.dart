import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';

void main() {
  group('AppDateFormat Tests', () {
    test(
      'formatDate formats DateTime into "dd MMM yyyy HH:mm"',
      () {
        final dt = DateTime(2026, 7, 8, 15, 21);
        expect(AppDateFormat.formatDate(dt), '08 Jul 2026 15:21');
      },
    );

    test(
      'formatGreeting formats DateTime into "Diperbarui Hari ini, HH.mm" for '
      'same day',
      () {
        final now = DateTime(2026, 7, 8, 18);
        final dt = DateTime(2026, 7, 8, 15, 20);
        expect(
          AppDateFormat.formatGreeting(dt, now: now),
          'Diperbarui Hari ini, 15.20',
        );
      },
    );

    test(
      'formatGreeting formats DateTime into "Diperbarui Kemarin, HH.mm" for '
      'yesterday',
      () {
        final now = DateTime(2026, 7, 9, 10);
        final dt = DateTime(2026, 7, 8, 15, 20);
        expect(
          AppDateFormat.formatGreeting(dt, now: now),
          'Diperbarui Kemarin, 15.20',
        );
      },
    );

    test(
      'formatGreeting formats DateTime with date when older in same year',
      () {
        final now = DateTime(2026, 9, 1, 10);
        final dt = DateTime(2026, 7, 8, 15, 20);
        expect(
          AppDateFormat.formatGreeting(dt, now: now),
          'Diperbarui 08 Jul, 15.20',
        );
      },
    );

    test(
      'formatGreeting formats DateTime with full year when in different year',
      () {
        final now = DateTime(2027, 1, 15, 10);
        final dt = DateTime(2026, 7, 8, 15, 20);
        expect(
          AppDateFormat.formatGreeting(dt, now: now),
          'Diperbarui 08 Jul 2026, 15.20',
        );
      },
    );

    test('tryParse parses ISO-8601 strings accurately', () {
      final parsed = AppDateFormat.tryParse(
        '2026-07-08T15:21:00.000Z',
      );
      expect(parsed, isNotNull);
      expect(parsed!.year, 2026);
      expect(parsed.month, 7);
      expect(parsed.day, 8);
    });

    test('tryParse parses Indonesian/English date text formats', () {
      final parsed = AppDateFormat.tryParse('08 Jul 2026 15:21');
      expect(parsed, isNotNull);
      expect(parsed!.year, 2026);
      expect(parsed.month, 7);
      expect(parsed.day, 8);
      expect(parsed.hour, 15);
      expect(parsed.minute, 21);
    });

    test('tryParse returns null for empty, null, or placeholder inputs', () {
      expect(AppDateFormat.tryParse(null), isNull);
      expect(AppDateFormat.tryParse(''), isNull);
      expect(AppDateFormat.tryParse('   '), isNull);
      expect(AppDateFormat.tryParse('-'), isNull);
      expect(AppDateFormat.tryParse('null'), isNull);
    });

    test(
      'formatRawDate converts raw ISO-8601 string to formatted date',
      () {
        final formatted = AppDateFormat.formatRawDate(
          '2026-07-08T15:21:00.000Z',
        );
        expect(formatted, isNot('-'));
        expect(formatted, isNot('2026-07-08T15:21:00.000Z'));
      },
    );

    test('formatRawDate preserves already formatted date string', () {
      expect(
        AppDateFormat.formatRawDate('08 Jul 2026 15:21'),
        '08 Jul 2026 15:21',
      );
    });

    test('formatRawGreeting converts timestamp into Diperbarui greeting', () {
      final now = DateTime(2026, 7, 8, 18);
      final formatted = AppDateFormat.formatRawGreeting(
        '08 Jul 2026 15:20',
        now: now,
      );
      expect(formatted, 'Diperbarui Hari ini, 15.20');
    });

    test(
      'formatRawGreeting preserves string already starting with Diperbarui',
      () {
        expect(
          AppDateFormat.formatRawGreeting('Diperbarui Hari ini, 15.20'),
          'Diperbarui Hari ini, 15.20',
        );
      },
    );

    test('formatRawGreeting returns "-" for empty or null inputs', () {
      expect(AppDateFormat.formatRawGreeting(null), '-');
      expect(AppDateFormat.formatRawGreeting(''), '-');
      expect(AppDateFormat.formatRawGreeting('   '), '-');
      expect(AppDateFormat.formatRawGreeting('-'), '-');
      expect(AppDateFormat.formatRawGreeting('null'), '-');
    });

    group('formatDateRange Tests', () {
      test('formats single day when start and end are the same', () {
        final start = DateTime(2026, 9, 13);
        final end = DateTime(2026, 9, 13);
        expect(AppDateFormat.formatDateRange(start, end), '13 Sep 2026');
      });

      test('formats same month and year without repeating month/year', () {
        final start = DateTime(2026, 9, 13);
        final end = DateTime(2026, 9, 14);
        expect(AppDateFormat.formatDateRange(start, end), '13–14 Sep 2026');
      });

      test('formats same year but different months without repeating year', () {
        final start = DateTime(2026, 9, 13);
        final end = DateTime(2026, 10, 14);
        expect(
          AppDateFormat.formatDateRange(start, end),
          '13 Sep – 14 Okt 2026',
        );
      });

      test('formats different years with full date on both ends', () {
        final start = DateTime(2026, 9, 13);
        final end = DateTime(2027, 9, 14);
        expect(
          AppDateFormat.formatDateRange(start, end),
          '13 Sep 2026 – 14 Sep 2027',
        );
      });

      test('normalizes chronological order when start is after end', () {
        final start = DateTime(2026, 9, 14);
        final end = DateTime(2026, 9, 13);
        expect(AppDateFormat.formatDateRange(start, end), '13–14 Sep 2026');
      });

      test('supports useLeadingZero flag when day is single-digit', () {
        final start = DateTime(2026, 9, 5);
        final end = DateTime(2026, 9, 8);
        expect(AppDateFormat.formatDateRange(start, end), '5–8 Sep 2026');
        expect(
          AppDateFormat.formatDateRange(start, end, useLeadingZero: true),
          '05–08 Sep 2026',
        );
      });
    });
  });
}
