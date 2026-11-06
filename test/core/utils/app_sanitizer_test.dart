import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/utils/app_sanitizer.dart';

void main() {
  group('AppSanitizer Tests', () {
    group('cleanString', () {
      test('returns null for null, empty, whitespace, and dirty strings', () {
        expect(AppSanitizer.cleanString(null), isNull);
        expect(AppSanitizer.cleanString(''), isNull);
        expect(AppSanitizer.cleanString('   '), isNull);
        expect(AppSanitizer.cleanString('N/A'), isNull);
        expect(AppSanitizer.cleanString('null'), isNull);
        expect(AppSanitizer.cleanString('-'), isNull);
      });

      test('returns trimmed string for valid inputs', () {
        expect(AppSanitizer.cleanString('  Budi Santoso  '), 'Budi Santoso');
        expect(AppSanitizer.cleanString('Pos 1'), 'Pos 1');
      });
    });

    group('cleanEmail', () {
      test('normalizes email to lowercase and trims whitespace', () {
        expect(
          AppSanitizer.cleanEmail('  BUDI@KAWALO.ID  '),
          'budi@kawalo.id',
        );
      });

      test('returns null for empty, placeholders, and invalid emails', () {
        expect(AppSanitizer.cleanEmail(null), isNull);
        expect(AppSanitizer.cleanEmail(''), isNull);
        expect(AppSanitizer.cleanEmail('   '), isNull);
        expect(AppSanitizer.cleanEmail('N/A'), isNull);
        expect(AppSanitizer.cleanEmail('null'), isNull);
        expect(AppSanitizer.cleanEmail('-'), isNull);
        expect(AppSanitizer.cleanEmail('invalid-email'), isNull);
      });
    });

    group('cleanPhone', () {
      test('normalizes international numbers and retains single plus prefix',
          () {
        expect(
          AppSanitizer.cleanPhone('  +62 (021) 555-0199  '),
          '+620215550199',
        );
      });

      test('normalizes local numbers without plus prefix', () {
        expect(
          AppSanitizer.cleanPhone('0812-3456-7890'),
          '081234567890',
        );
      });

      test('cleans wild plus signs and non-digit characters in between', () {
        expect(AppSanitizer.cleanPhone('+62+812+345'), '+62812345');
        expect(AppSanitizer.cleanPhone('021+555'), '021555');
      });

      test('returns null for empty, placeholders, and digitless strings', () {
        expect(AppSanitizer.cleanPhone(null), isNull);
        expect(AppSanitizer.cleanPhone(''), isNull);
        expect(AppSanitizer.cleanPhone('   '), isNull);
        expect(AppSanitizer.cleanPhone('N/A'), isNull);
        expect(AppSanitizer.cleanPhone('null'), isNull);
        expect(AppSanitizer.cleanPhone('-'), isNull);
        expect(AppSanitizer.cleanPhone('+'), isNull);
        expect(AppSanitizer.cleanPhone('+++'), isNull);
        expect(AppSanitizer.cleanPhone('+abc'), isNull);
        expect(AppSanitizer.cleanPhone('abc-def'), isNull);
      });
    });

    group('cleanRole', () {
      test('uppercases and trims valid roles', () {
        expect(AppSanitizer.cleanRole('admin'), 'ADMIN');
        expect(AppSanitizer.cleanRole('  guard  '), 'GUARD');
        expect(AppSanitizer.cleanRole('CITIZEN'), 'CITIZEN');
      });

      test('returns null for empty, placeholder, or dirty values', () {
        expect(AppSanitizer.cleanRole(null), isNull);
        expect(AppSanitizer.cleanRole(''), isNull);
        expect(AppSanitizer.cleanRole('   '), isNull);
        expect(AppSanitizer.cleanRole('N/A'), isNull);
        expect(AppSanitizer.cleanRole('null'), isNull);
      });
    });

    group('cleanDate', () {
      test('returns valid date string', () {
        expect(
          AppSanitizer.cleanDate('2026-09-10T07:10:00.000Z'),
          '2026-09-10T07:10:00.000Z',
        );
      });

      test('ignores legacy epoch dates and empty placeholders', () {
        expect(
          AppSanitizer.cleanDate('1970-01-01T00:00:00.000Z'),
          isNull,
        );
        expect(AppSanitizer.cleanDate('0000-00-00 00:00:00'), isNull);
        expect(AppSanitizer.cleanDate('N/A'), isNull);
        expect(AppSanitizer.cleanDate('   '), isNull);
      });
    });

    group('cleanTimeWindow', () {
      test('returns valid time window string', () {
        expect(
          AppSanitizer.cleanTimeWindow('07:00 - 15:00'),
          '07:00 - 15:00',
        );
      });

      test('ignores dummy zero time windows and placeholders', () {
        expect(AppSanitizer.cleanTimeWindow(null), isNull);
        expect(AppSanitizer.cleanTimeWindow(''), isNull);
        expect(AppSanitizer.cleanTimeWindow('00:00:00'), isNull);
        expect(AppSanitizer.cleanTimeWindow('00:00'), isNull);
        expect(AppSanitizer.cleanTimeWindow('N/A'), isNull);
      });
    });

    group('cleanInteger', () {
      test('parses int, double, and string numbers correctly', () {
        expect(AppSanitizer.cleanInteger(15), 15);
        expect(AppSanitizer.cleanInteger(-10), -10);
        expect(AppSanitizer.cleanInteger(12.75), 12);
        expect(AppSanitizer.cleanInteger('-5'), -5);
        expect(AppSanitizer.cleanInteger('  25  '), 25);
        expect(AppSanitizer.cleanInteger(' 12.4 '), 12);
      });

      test('returns null for null, NaN, Infinity, and invalid strings', () {
        expect(AppSanitizer.cleanInteger(null), isNull);
        expect(AppSanitizer.cleanInteger(double.nan), isNull);
        expect(AppSanitizer.cleanInteger(double.infinity), isNull);
        expect(AppSanitizer.cleanInteger('N/A'), isNull);
        expect(AppSanitizer.cleanInteger('invalid'), isNull);
      });
    });

    group('cleanCoordinate', () {
      test('returns valid coordinates as trimmed string', () {
        expect(AppSanitizer.cleanCoordinate('-6.2088'), '-6.2088');
        expect(AppSanitizer.cleanCoordinate(' 106.8456 '), '106.8456');
      });

      test('ignores dummy zero coordinates or non-numeric/out-of-range strings',
          () {
        expect(AppSanitizer.cleanCoordinate('0'), isNull);
        expect(AppSanitizer.cleanCoordinate('0.0'), isNull);
        expect(AppSanitizer.cleanCoordinate('0.000000'), isNull);
        expect(AppSanitizer.cleanCoordinate('not_a_number'), isNull);
        expect(AppSanitizer.cleanCoordinate('200.0'), isNull);
        expect(AppSanitizer.cleanCoordinate('-200.0'), isNull);
        expect(AppSanitizer.cleanCoordinate('N/A'), isNull);
      });

      test('validates latitude bounds (-90..90)', () {
        expect(AppSanitizer.cleanLatitude('-6.2088'), '-6.2088');
        expect(AppSanitizer.cleanLatitude('90.0'), '90.0');
        expect(AppSanitizer.cleanLatitude('-90.0'), '-90.0');
        expect(AppSanitizer.cleanLatitude('91.0'), isNull);
        expect(AppSanitizer.cleanLatitude('-91.0'), isNull);
      });

      test('validates longitude bounds (-180..180)', () {
        expect(AppSanitizer.cleanLongitude('106.8456'), '106.8456');
        expect(AppSanitizer.cleanLongitude('180.0'), '180.0');
        expect(AppSanitizer.cleanLongitude('-180.0'), '-180.0');
        expect(AppSanitizer.cleanLongitude('181.0'), isNull);
        expect(AppSanitizer.cleanLongitude('-181.0'), isNull);
      });

      test('validates double coordinate conversions', () {
        expect(AppSanitizer.cleanLatitudeDouble('-6.2088'), -6.2088);
        expect(AppSanitizer.cleanLatitudeDouble('91.0'), isNull);
        expect(AppSanitizer.cleanLongitudeDouble('106.8456'), 106.8456);
        expect(AppSanitizer.cleanLongitudeDouble('181.0'), isNull);
      });

      test('isValidLatitude validates physical latitude bounds', () {
        expect(AppSanitizer.isValidLatitude(-6.2088), isTrue);
        expect(AppSanitizer.isValidLatitude(0.0), isTrue);
        expect(AppSanitizer.isValidLatitude(0), isTrue);
        expect(AppSanitizer.isValidLatitude(90.0), isTrue);
        expect(AppSanitizer.isValidLatitude(-90.0), isTrue);
        expect(AppSanitizer.isValidLatitude(90.1), isFalse);
        expect(AppSanitizer.isValidLatitude(-90.1), isFalse);
        expect(AppSanitizer.isValidLatitude(double.nan), isFalse);
        expect(AppSanitizer.isValidLatitude(double.infinity), isFalse);
        expect(AppSanitizer.isValidLatitude(double.negativeInfinity), isFalse);
        expect(AppSanitizer.isValidLatitude(null), isFalse);
      });

      test('isValidLongitude validates physical longitude bounds', () {
        expect(AppSanitizer.isValidLongitude(106.8456), isTrue);
        expect(AppSanitizer.isValidLongitude(0.0), isTrue);
        expect(AppSanitizer.isValidLongitude(0), isTrue);
        expect(AppSanitizer.isValidLongitude(180.0), isTrue);
        expect(AppSanitizer.isValidLongitude(-180.0), isTrue);
        expect(AppSanitizer.isValidLongitude(180.1), isFalse);
        expect(AppSanitizer.isValidLongitude(-180.1), isFalse);
        expect(AppSanitizer.isValidLongitude(double.nan), isFalse);
        expect(AppSanitizer.isValidLongitude(double.infinity), isFalse);
        expect(AppSanitizer.isValidLongitude(double.negativeInfinity), isFalse);
        expect(AppSanitizer.isValidLongitude(null), isFalse);
      });

      test('isValidCoordinates validates both axes jointly', () {
        expect(
          AppSanitizer.isValidCoordinates(
            latitude: -6.2088,
            longitude: 106.8456,
          ),
          isTrue,
        );
        expect(
          AppSanitizer.isValidCoordinates(latitude: 0, longitude: 0),
          isTrue,
        );
        expect(
          AppSanitizer.isValidCoordinates(latitude: 95.0, longitude: 106.8),
          isFalse,
        );
        expect(
          AppSanitizer.isValidCoordinates(latitude: -6.2, longitude: 190.0),
          isFalse,
        );
        expect(
          AppSanitizer.isValidCoordinates(
            latitude: double.nan,
            longitude: 106.8,
          ),
          isFalse,
        );
      });
    });

    group('cleanStringList', () {
      test('discards empty/dummy values and returns fixed-length list', () {
        final list = ['A', '', '  ', 'B', 'N/A', 'null', '-'];
        final cleaned = AppSanitizer.cleanStringList(list);

        expect(cleaned, ['A', 'B']);
        expect(AppSanitizer.cleanStringList(null), isEmpty);
        expect(AppSanitizer.cleanStringList(const []), isEmpty);
        expect(() => cleaned.add('C'), throwsUnsupportedError);
      });
    });

    group('stripFilePaths', () {
      test('masks Unix absolute paths with [path]', () {
        const input = 'Error at /data/user/0/id.kawalo.app/files/db.isar';
        expect(
          AppSanitizer.stripFilePaths(input),
          equals('Error at [path]'),
        );
      });

      test('masks Windows absolute paths with [path]', () {
        const input = r'Error at C:\Users\User\AppData\Local\cache.db';
        expect(
          AppSanitizer.stripFilePaths(input),
          equals('Error at [path]'),
        );
      });

      test('masks Windows absolute paths containing spaces entirely', () {
        const input = r'Cannot open C:\Users\MxK\Kiero Project\photo.jpg';
        final result = AppSanitizer.stripFilePaths(input);
        expect(result, equals('Cannot open [path]'));
        expect(result.contains('Kiero'), isFalse);
        expect(result.contains('photo.jpg'), isFalse);
      });

      test('keeps strings without paths unchanged', () {
        expect(
          AppSanitizer.stripFilePaths('No space left on device'),
          equals('No space left on device'),
        );
      });

      test('handles empty and null inputs safely', () {
        expect(AppSanitizer.stripFilePaths(''), equals(''));
        expect(AppSanitizer.stripFilePaths(null), equals(''));
      });
    });
  });
}
