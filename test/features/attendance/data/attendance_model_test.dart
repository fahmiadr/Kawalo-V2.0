import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/attendance/data/models/attendance_model.dart';

void main() {
  group('AttendanceModel Tests', () {
    test('fromJson serializes backend snake_case map properly', () {
      final json = {
        'id': '101',
        'user_email': 'budi@kawalo.id',
        'user_name': 'Budi Santoso',
        'user_profile_pic': 'https://example.com/pic.jpg',
        'user_duty': 'ON DUTY',
        'attendance_dt': '2026-09-10T07:05:00.000Z',
        'attendance_type': 'Absen Masuk shift pagi',
        'category': 'MASUK',
        'diff_minutes': 5,
        'location_name': 'Pos Gerbang Utama',
        'latitude': '-6.2088',
        'longitude': '106.8456',
        'shift_name': 'Shift Pagi',
        'shift_color': '#10B981',
        'shift_time_window': '07:00 - 15:00',
        'group_uid': 'GRP-01',
        'group_name': 'Cluster Edelweiss',
      };

      final model = AttendanceModel.fromJson(json);

      expect(model.id, '101');
      expect(model.userEmail, 'budi@kawalo.id');
      expect(model.userName, 'Budi Santoso');
      expect(model.userProfilePic, 'https://example.com/pic.jpg');
      expect(model.userDuty, 'ON DUTY');
      expect(model.category, 'MASUK');
      expect(model.diffMinutes, 5);
      expect(model.locationName, 'Pos Gerbang Utama');
      expect(model.latitude, '-6.2088');
      expect(model.longitude, '106.8456');
      expect(model.shiftName, 'Shift Pagi');
      expect(model.shiftTimeWindow, '07:00 - 15:00');
      expect(model.groupName, 'Cluster Edelweiss');
    });

    test('fromJson preserves null values for nullable fields without '
        'empty string fallback', () {
      final json = {
        'id': '103',
        'category': 'lainnya',
        'diff_minutes': 0,
        'user_email': null,
        'user_name': null,
        'user_profile_pic': null,
        'user_duty': null,
        'attendance_dt': null,
        'attendance_type': null,
        'latitude': null,
        'longitude': null,
        'location_name': null,
        'shift_name': null,
        'shift_color': null,
        'shift_time_window': null,
        'group_uid': null,
        'group_name': null,
      };

      final model = AttendanceModel.fromJson(json);

      expect(model.id, '103');
      expect(model.category, 'lainnya');
      expect(model.diffMinutes, 0);
      expect(model.userEmail, isNull);
      expect(model.userName, isNull);
      expect(model.attendanceDt, isNull);
      expect(model.attendanceType, isNull);
      expect(model.locationName, isNull);
    });

    test(
      'fromJson throws TypeError when required non-null fields are missing',
      () {
        final jsonMissingId = {'category': 'masuk', 'diff_minutes': 0};
        expect(
          () => AttendanceModel.fromJson(jsonMissingId),
          throwsA(isA<TypeError>()),
        );

        final jsonMissingCategory = {'id': '104', 'diff_minutes': 0};
        expect(
          () => AttendanceModel.fromJson(jsonMissingCategory),
          throwsA(isA<TypeError>()),
        );
      },
    );

    test('fromJson defaults diff_minutes to 0 when missing or null', () {
      final base = {'id': '105', 'category': 'masuk'};

      expect(AttendanceModel.fromJson(base).diffMinutes, 0);
      expect(
        AttendanceModel.fromJson({...base, 'diff_minutes': null}).diffMinutes,
        0,
      );
    });

    test('fromJson accepts decimal and negative diff_minutes', () {
      final base = {'id': '106', 'category': 'masuk'};

      expect(
        AttendanceModel.fromJson({...base, 'diff_minutes': 5.0}).diffMinutes,
        5,
      );
      expect(
        AttendanceModel.fromJson({...base, 'diff_minutes': -3}).diffMinutes,
        -3,
      );
    });
  });
}
