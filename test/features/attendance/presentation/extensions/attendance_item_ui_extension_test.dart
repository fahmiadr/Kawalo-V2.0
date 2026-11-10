import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';
import 'package:kawalo_mobile/features/attendance/presentation/extensions/attendance_item_ui_extension.dart';

void main() {
  group('AttendanceItemUiExtension Tests', () {
    test('tagVariant and displayCategory detect masuk properly', () {
      const entity = AttendanceItemEntity(
        id: '1',
        category: 'MASUK',
        diffMinutes: 0,
        userEmail: 'guard@kawalo.id',
        userName: 'Ahmad',
        attendanceDt: '2026-09-10T07:00:00.000Z',
        attendanceType: 'Absen Masuk shift pagi',
        locationName: 'Pos 1',
      );

      expect(entity.tagVariant, AppTagVariant.primary);
      expect(entity.displayCategory, 'Masuk');
    });

    test('tagVariant and displayCategory detect pulang properly', () {
      const entity = AttendanceItemEntity(
        id: '2',
        category: 'PULANG',
        diffMinutes: 10,
        userEmail: 'guard@kawalo.id',
        userName: 'Ahmad',
        attendanceDt: '2026-09-10T15:00:00.000Z',
        attendanceType: 'CHECK OUT',
        locationName: 'Pos 1',
      );

      expect(entity.tagVariant, AppTagVariant.secondary);
      expect(entity.displayCategory, 'Pulang');
    });

    test('tagVariant and displayCategory fallback for other types', () {
      const entity = AttendanceItemEntity(
        id: '3',
        category: 'LAINNYA',
        diffMinutes: 0,
        userEmail: 'guard@kawalo.id',
        userName: 'Ahmad',
        attendanceDt: '2026-09-10T12:00:00.000Z',
        attendanceType: 'REGISTER',
        locationName: 'Pos 1',
      );

      expect(entity.tagVariant, AppTagVariant.neutral);
      expect(entity.displayCategory, 'REGISTER');
    });

    test('displayShift formats shift name and time window', () {
      const itemWithWindow = AttendanceItemEntity(
        id: '1',
        category: 'MASUK',
        diffMinutes: 0,
        userEmail: 'guard@kawalo.id',
        userName: 'Ahmad',
        attendanceDt: '2026-09-10T07:00:00.000Z',
        attendanceType: 'CHECK IN',
        locationName: 'Pos 1',
        shiftName: 'Shift Pagi',
        shiftTimeWindow: '07:00 - 15:00',
      );
      expect(itemWithWindow.displayShift, 'Shift Pagi • 07:00 - 15:00');

      const itemWithoutWindow = AttendanceItemEntity(
        id: '2',
        category: 'MASUK',
        diffMinutes: 0,
        userEmail: 'guard@kawalo.id',
        userName: 'Ahmad',
        attendanceDt: '2026-09-10T07:00:00.000Z',
        attendanceType: 'CHECK IN',
        locationName: 'Pos 1',
        shiftName: 'Shift Khusus',
      );
      expect(itemWithoutWindow.displayShift, 'Shift Khusus');
    });

    test('display getters provide em-dash fallback when values are null', () {
      const emptyEntity = AttendanceItemEntity(
        id: '99',
        category: 'LAINNYA',
        diffMinutes: 0,
      );

      expect(emptyEntity.displayUserName, '—');
      expect(emptyEntity.displayUserEmail, '—');
      expect(emptyEntity.displayLocationName, '—');
      expect(emptyEntity.displayGroupName, '—');
      expect(emptyEntity.displayAttendanceType, '—');
      expect(emptyEntity.displayUserDuty, '—');
      expect(emptyEntity.displayAttendanceDt, '—');
      expect(emptyEntity.displayShiftName, '—');
      expect(emptyEntity.displayShiftTimeWindow, '—');
      expect(emptyEntity.displayShift, '—');
      expect(emptyEntity.displayCategory, '—');
    });

    group('shiftAccentColor', () {
      AttendanceItemEntity withColor(String? value) => AttendanceItemEntity(
        id: '1',
        category: 'MASUK',
        diffMinutes: 0,
        shiftColor: value,
      );

      test('parses #RRGGBB and RRGGBB into an opaque colour', () {
        expect(withColor('#FF5722').shiftAccentColor, const Color(0xFFFF5722));
        expect(withColor(' 2e7d32 ').shiftAccentColor, const Color(0xFF2E7D32));
      });

      test('ignores empty, malformed and non-hex values', () {
        for (final value in [null, '', '  ', '#FFF', 'merah', '#GG0000']) {
          expect(withColor(value).shiftAccentColor, isNull, reason: '$value');
        }
      });

      test('drops purple hues but keeps greys and other colours', () {
        expect(withColor('#7B1FA2').shiftAccentColor, isNull);
        expect(withColor('#9C27B0').shiftAccentColor, isNull);
        expect(withColor('#808080').shiftAccentColor, isNotNull);
        expect(withColor('#1565C0').shiftAccentColor, isNotNull);
      });
    });
  });
}
