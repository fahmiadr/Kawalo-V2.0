import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/extensions/manual_request_ui_extension.dart';

import '../fixtures.dart';

void main() {
  test('the distance is measured from the attendance point', () {
    expect(
      manualRequest().displayDistance,
      '42 m dari titik absen (radius 100 m)',
    );
  });
}
