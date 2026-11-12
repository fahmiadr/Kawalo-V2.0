import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/attendance/data/mappers/attendance_mapper.dart';
import 'package:kawalo_mobile/features/attendance/data/models/attendance_model.dart';
import 'package:kawalo_mobile/features/attendance/presentation/extensions/attendance_item_ui_extension.dart';

void main() {
  AttendanceModel parse(Map<String, dynamic> extra) => AttendanceModel.fromJson(
    {'id': '1', 'category': 'masuk', 'diff_minutes': 0, ...extra},
  );

  test('avatar_url is preferred, user_profile_pic stays as fallback', () {
    final both = AttendanceMapper.toEntity(
      parse({
        'avatar_url': 'https://x.id/new.webp',
        'user_profile_pic': 'https://x.id/old.webp',
      }),
    );
    final legacy = AttendanceMapper.toEntity(
      parse({'user_profile_pic': 'https://x.id/old.webp'}),
    );

    expect(both.displayAvatarUrl, 'https://x.id/new.webp');
    expect(legacy.avatarUrl, isNull);
    expect(legacy.displayAvatarUrl, 'https://x.id/old.webp');
    expect(AttendanceMapper.toEntity(parse({})).displayAvatarUrl, isNull);
  });
}
