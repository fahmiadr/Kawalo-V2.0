import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/utils/app_display_formatter.dart';

void main() {
  group('AppDisplayFormatter Core Functions Tests', () {
    test('isBlank accurately detects null, empty, and whitespace strings', () {
      expect(AppDisplayFormatter.isBlank(null), isTrue);
      expect(AppDisplayFormatter.isBlank(''), isTrue);
      expect(AppDisplayFormatter.isBlank('   '), isTrue);
      expect(AppDisplayFormatter.isBlank('\n\t'), isTrue);
      expect(AppDisplayFormatter.isBlank('hello'), isFalse);
      expect(AppDisplayFormatter.isBlank('  a  '), isFalse);
    });

    test('toDisplay defaults to em-dash when value is null or empty', () {
      expect(AppDisplayFormatter.toDisplay(null), AppDisplayFormatter.emDash);
      expect(AppDisplayFormatter.toDisplay(''), AppDisplayFormatter.emDash);
      expect(AppDisplayFormatter.toDisplay('   '), AppDisplayFormatter.emDash);
      expect(AppDisplayFormatter.toDisplay('Kawalo'), 'Kawalo');
      expect(AppDisplayFormatter.toDisplay('  Pos 1  '), 'Pos 1');
    });

    test('toDisplay respects custom fallback parameter', () {
      expect(
        AppDisplayFormatter.toDisplay(null, fallback: AppDisplayFormatter.dash),
        '-',
      );
      expect(
        AppDisplayFormatter.toDisplay('Ada', fallback: 'Tidak ada'),
        'Ada',
      );
    });

    test('toDisplayNotAvailable returns Tidak tersedia for blank values', () {
      expect(AppDisplayFormatter.toDisplayNotAvailable(null), 'Tidak tersedia');
      expect(AppDisplayFormatter.toDisplayNotAvailable('  '), 'Tidak tersedia');
      expect(AppDisplayFormatter.toDisplayNotAvailable('Ada'), 'Ada');
    });

    test('toDisplayNotSet returns Belum diatur for blank values', () {
      expect(AppDisplayFormatter.toDisplayNotSet(null), 'Belum diatur');
      expect(AppDisplayFormatter.toDisplayNotSet('  '), 'Belum diatur');
      expect(
        AppDisplayFormatter.toDisplayNotSet('07:00 - 15:00'),
        '07:00 - 15:00',
      );
    });

    test('toDisplayUnrecorded returns Tidak tercatat for blank values', () {
      expect(AppDisplayFormatter.toDisplayUnrecorded(null), 'Tidak tercatat');
      expect(AppDisplayFormatter.toDisplayUnrecorded(' '), 'Tidak tercatat');
      expect(
        AppDisplayFormatter.toDisplayUnrecorded('-6.2088, 106.8456'),
        '-6.2088, 106.8456',
      );
    });

    test('toDisplayExplicit returns provided custom fallback for blanks', () {
      expect(AppDisplayFormatter.toDisplayExplicit(null, 'Khusus'), 'Khusus');
      expect(AppDisplayFormatter.toDisplayExplicit('  ', 'Khusus'), 'Khusus');
      expect(AppDisplayFormatter.toDisplayExplicit('Valid', 'Khusus'), 'Valid');
    });

    test(
      'toDisplayFormat applies custom formatter callback or returns fallback',
      () {
        expect(
          AppDisplayFormatter.toDisplayFormat(
            'pagi',
            (val) => 'Shift ${val.toUpperCase()}',
          ),
          'Shift PAGI',
        );

        expect(
          AppDisplayFormatter.toDisplayFormat(null, (val) => 'Shift $val'),
          AppDisplayFormatter.emDash,
        );

        expect(
          AppDisplayFormatter.toDisplayFormat(
            '   ',
            (val) => 'Shift $val',
            fallback: 'Shift Umum',
          ),
          'Shift Umum',
        );

        expect(
          AppDisplayFormatter.toDisplayFormat(
            '2026-09-10T07:05:00.000Z',
            AppDateFormat.formatRawDate,
          ),
          AppDateFormat.formatRawDate('2026-09-10T07:05:00.000Z'),
        );
      },
    );
  });

  group('DisplayGetterExtension Tests', () {
    test('toDisplay extension works with em-dash and custom fallback', () {
      const String? nullValue = null;
      expect(nullValue.toDisplay(), AppDisplayFormatter.emDash);
      expect(''.toDisplay(), AppDisplayFormatter.emDash);
      expect('   '.toDisplay(), AppDisplayFormatter.emDash);
      expect('Pos Utama'.toDisplay(), 'Pos Utama');
      expect(nullValue.toDisplay(fallback: '-'), '-');
    });

    test('preset toDisplay extensions work as expected', () {
      const String? nullValue = null;
      expect(nullValue.toDisplayNotAvailable(), 'Tidak tersedia');
      expect(nullValue.toDisplayNotSet(), 'Belum diatur');
      expect(nullValue.toDisplayUnrecorded(), 'Tidak tercatat');
      expect(nullValue.toDisplayExplicit('Kustom'), 'Kustom');

      expect('Ada'.toDisplayNotAvailable(), 'Ada');
      expect('Ada'.toDisplayNotSet(), 'Ada');
      expect('Ada'.toDisplayUnrecorded(), 'Ada');
      expect('Ada'.toDisplayExplicit('Kustom'), 'Ada');
    });

    test('toDisplayFormat extension applies transformer callback', () {
      const String? nullVal = null;
      expect(
        nullVal.toDisplayFormat((val) => '[$val]'),
        AppDisplayFormatter.emDash,
      );
      expect('Petugas'.toDisplayFormat((val) => '[$val]'), '[Petugas]');

      const dateStr = '2026-09-10T07:05:00.000Z';
      expect(
        dateStr.toDisplayFormat(AppDateFormat.formatRawDate),
        AppDateFormat.formatRawDate(dateStr),
      );
      expect(
        nullVal.toDisplayFormat(AppDateFormat.formatRawDate),
        AppDisplayFormatter.emDash,
      );
    });

    test('isNullOrBlank extension property works accurately', () {
      const String? nullVal = null;
      expect(nullVal.isNullOrBlank, isTrue);
      expect(''.isNullOrBlank, isTrue);
      expect('   '.isNullOrBlank, isTrue);
      expect('Valid'.isNullOrBlank, isFalse);
    });
  });
}
