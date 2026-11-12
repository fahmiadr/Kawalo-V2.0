import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/attendance_admin/data/models/manual_request_model.dart';

void main() {
  test('manual request reads avatar_url, null when absent', () {
    expect(
      const ManualRequestModel({
        'avatar_url': 'https://x.id/a.webp',
      }).toEntity().avatarUrl,
      'https://x.id/a.webp',
    );
    expect(const ManualRequestModel({}).toEntity().avatarUrl, isNull);
  });
}
