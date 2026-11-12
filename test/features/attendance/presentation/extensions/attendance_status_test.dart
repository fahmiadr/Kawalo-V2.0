import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';
import 'package:kawalo_mobile/features/attendance/presentation/extensions/attendance_item_ui_extension.dart';

AttendanceItemEntity _item(
  String category, {
  int diff = 0,
  int? early,
  bool? faceVerified,
}) => AttendanceItemEntity(
  id: '1',
  category: category,
  diffMinutes: diff,
  earlyLeaveMinutes: early,
  faceVerified: faceVerified,
);

void main() {
  group('status colour: late check-in and early check-out are red', () {
    test('check-in late is red, on time or early is green', () {
      expect(_item('MASUK', diff: 5).statusVariant, AppTagVariant.error);
      expect(_item('MASUK', diff: 5).displayDiffLabel, 'Terlambat 5 menit');
      expect(_item('MASUK').statusVariant, AppTagVariant.primary);
      expect(_item('MASUK', diff: -8).statusVariant, AppTagVariant.primary);
      expect(_item('MASUK', diff: -8).displayDiffLabel, 'Lebih awal 8 menit');
      expect(
        _item('PULANG', diff: -845).displayDiffLabel,
        'Lebih awal 14 jam 5 menit',
      );
    });

    test('check-out before the shift end is red, otherwise green', () {
      final early = _item('PULANG', early: 12);
      expect(early.statusVariant, AppTagVariant.error);
      expect(early.displayDiffLabel, 'Pulang lebih cepat 12 menit');

      final onTime = _item('PULANG', early: 0);
      expect(onTime.statusVariant, AppTagVariant.primary);
      expect(onTime.displayDiffLabel, 'Tepat waktu');
    });

    test('check-out ignores diffMinutes once early minutes are known', () {
      expect(
        _item('PULANG', diff: 9, early: 0).statusVariant,
        AppTagVariant.primary,
      );
    });

    test('check-out without early minutes falls back to diffMinutes', () {
      expect(_item('PULANG').statusVariant, AppTagVariant.primary);
      expect(_item('PULANG', diff: 3).statusVariant, AppTagVariant.error);
    });
  });

  test('isUnverified only when the server says the face did not match', () {
    expect(_item('MASUK', faceVerified: false).isUnverified, isTrue);
    expect(_item('MASUK', faceVerified: true).isUnverified, isFalse);
    expect(_item('MASUK').isUnverified, isFalse);
  });
}
