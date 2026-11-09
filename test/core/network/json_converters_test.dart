import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/json_converters.dart';

void main() {
  group('IntFromNumConverter', () {
    const converter = IntFromNumConverter();

    test('accepts int and decimal numbers', () {
      expect(converter.fromJson(900), 900);
      expect(converter.fromJson(900.0), 900);
      expect(converter.fromJson(12.7), 12);
    });

    test('throws on null or non-numeric values', () {
      expect(() => converter.fromJson(null), throwsA(isA<TypeError>()));
      expect(() => converter.fromJson('900'), throwsA(isA<TypeError>()));
    });
  });

  group('NullableIntFromNumConverter', () {
    const converter = NullableIntFromNumConverter();

    test('keeps null and converts numbers', () {
      expect(converter.fromJson(null), isNull);
      expect(converter.fromJson(5), 5);
      expect(converter.fromJson(5.0), 5);
    });
  });
}
