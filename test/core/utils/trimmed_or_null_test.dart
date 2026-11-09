import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/utils/trimmed_or_null.dart';

void main() {
  group('TrimmedOrNull', () {
    test('returns null for null, empty and whitespace-only values', () {
      const String? nothing = null;
      expect(nothing.trimmedOrNull, isNull);
      expect(''.trimmedOrNull, isNull);
      expect('  \t\n'.trimmedOrNull, isNull);
    });

    test('returns the trimmed value otherwise', () {
      expect('  abc '.trimmedOrNull, 'abc');
      expect('a b'.trimmedOrNull, 'a b');
    });
  });
}
