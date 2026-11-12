import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/utils/duration_text.dart';

void main() {
  test('formatMinutes reads minutes as hours and minutes', () {
    expect(formatMinutes(0), '0 menit');
    expect(formatMinutes(5), '5 menit');
    expect(formatMinutes(59), '59 menit');
    expect(formatMinutes(60), '1 jam');
    expect(formatMinutes(61), '1 jam 1 menit');
    expect(formatMinutes(120), '2 jam');
    expect(formatMinutes(845), '14 jam 5 menit');
    expect(formatMinutes(1500), '25 jam');
    expect(formatMinutes(-845), '14 jam 5 menit');
  });
}
