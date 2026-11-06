import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';

void main() {
  group('AttendanceItemEntity Domain Tests', () {
    test('isLate and isOnTime calculate correctly', () {
      const onTime = AttendanceItemEntity(
        id: '1',
        category: 'MASUK',
        diffMinutes: 0,
        userEmail: 'guard@kawalo.id',
        userName: 'Ahmad',
        attendanceDt: '2026-09-10T07:00:00.000Z',
        attendanceType: 'CHECK IN',
        locationName: 'Pos 1',
      );
      expect(onTime.isOnTime, isTrue);
      expect(onTime.isLate, isFalse);

      const late = AttendanceItemEntity(
        id: '2',
        category: 'MASUK',
        diffMinutes: 15,
        userEmail: 'guard@kawalo.id',
        userName: 'Ahmad',
        attendanceDt: '2026-09-10T07:15:00.000Z',
        attendanceType: 'CHECK IN',
        locationName: 'Pos 1',
      );
      expect(late.isLate, isTrue);
      expect(late.isOnTime, isFalse);

      const early = AttendanceItemEntity(
        id: '3',
        category: 'MASUK',
        diffMinutes: -10,
        userEmail: 'guard@kawalo.id',
        userName: 'Ahmad',
        attendanceDt: '2026-09-10T06:50:00.000Z',
        attendanceType: 'CHECK IN',
        locationName: 'Pos 1',
      );
      expect(early.isOnTime, isTrue);
      expect(early.isLate, isFalse);
    });

    test('latitude and longitude hold double coordinates correctly', () {
      const valid = AttendanceItemEntity(
        id: '1',
        category: 'MASUK',
        diffMinutes: 0,
        userEmail: 'guard@kawalo.id',
        userName: 'Ahmad',
        attendanceDt: '2026-09-10T07:00:00.000Z',
        attendanceType: 'CHECK IN',
        locationName: 'Pos 1',
        latitude: -6.2088,
        longitude: 106.8456,
      );
      expect(valid.latitude, -6.2088);
      expect(valid.longitude, 106.8456);

      const nullCoords = AttendanceItemEntity(
        id: '2',
        category: 'MASUK',
        diffMinutes: 0,
        userEmail: 'guard@kawalo.id',
        userName: 'Ahmad',
        attendanceDt: '2026-09-10T07:00:00.000Z',
        attendanceType: 'CHECK IN',
        locationName: 'Pos 1',
      );
      expect(nullCoords.latitude, isNull);
      expect(nullCoords.longitude, isNull);
    });

    test('props equality compares identical entities as equal', () {
      const entity1 = AttendanceItemEntity(
        id: '1',
        category: 'MASUK',
        diffMinutes: 0,
        userName: 'Budi',
      );
      const entity2 = AttendanceItemEntity(
        id: '1',
        category: 'MASUK',
        diffMinutes: 0,
        userName: 'Budi',
      );
      const entity3 = AttendanceItemEntity(
        id: '2',
        category: 'PULANG',
        diffMinutes: 5,
        userName: 'Agus',
      );

      expect(entity1, equals(entity2));
      expect(entity1 == entity3, isFalse);
    });
  });
}
