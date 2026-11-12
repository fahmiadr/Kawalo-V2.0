import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/attendance_admin/data/models/attendance_setting_model.dart';

void main() {
  test('parses the full payload', () {
    final entity = const AttendanceSettingModel({
      'face_match_percent': 55,
      'default_percent': 40,
      'min_percent': 20,
      'max_percent': 95,
      'is_default': false,
      'updated_by': 'admin@kawalo.id',
      'updated_at': '2026-11-12T01:00:00.000Z',
    }).toEntity();

    expect(entity.faceMatchPercent, 55);
    expect(entity.defaultPercent, 40);
    expect(entity.minPercent, 20);
    expect(entity.maxPercent, 95);
    expect(entity.isDefault, isFalse);
    expect(entity.updatedBy, 'admin@kawalo.id');
    expect(entity.updatedAt, '2026-11-12T01:00:00.000Z');
  });

  test('missing fields fall back to the documented limits', () {
    final entity = const AttendanceSettingModel({'updated_by': ''}).toEntity();

    expect(entity.faceMatchPercent, 40);
    expect(entity.minPercent, 20);
    expect(entity.maxPercent, 95);
    expect(entity.isDefault, isTrue);
    expect(entity.updatedBy, isNull);
  });
}
