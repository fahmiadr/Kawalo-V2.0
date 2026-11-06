import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/attendance/data/mappers/attendance_mapper.dart';
import 'package:kawalo_mobile/features/attendance/data/models/attendance_model.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';

void main() {
  group('AttendanceMapper Tests', () {
    const testModel = AttendanceModel(
      id: 'ATT-101',
      category: 'MASUK',
      diffMinutes: 10,
      userEmail: 'budi@kawalo.id',
      userName: 'Budi Santoso',
      userProfilePic: 'https://example.com/pic.jpg',
      userDuty: 'ON DUTY',
      attendanceDt: '2026-09-10T07:10:00.000Z',
      attendanceType: 'Absen Masuk shift pagi',
      latitude: '-6.2088',
      longitude: '106.8456',
      locationName: 'Pos Gerbang Utama',
      shiftName: 'Shift Pagi',
      shiftColor: '#10B981',
      shiftTimeWindow: '07:00 - 15:00',
      groupName: 'Cluster Edelweiss',
    );

    test('toEntity accurately maps all fields from Model to Entity', () {
      final entity = AttendanceMapper.toEntity(testModel);

      expect(entity, isA<AttendanceItemEntity>());
      expect(entity.id, testModel.id);
      expect(entity.category, testModel.category);
      expect(entity.diffMinutes, testModel.diffMinutes);
      expect(entity.userEmail, testModel.userEmail);
      expect(entity.userName, testModel.userName);
      expect(entity.userProfilePic, testModel.userProfilePic);
      expect(entity.userDuty, testModel.userDuty);
      expect(entity.attendanceDt, testModel.attendanceDt);
      expect(entity.attendanceType, testModel.attendanceType);
      expect(entity.latitude, -6.2088);
      expect(entity.longitude, 106.8456);
      expect(entity.locationName, testModel.locationName);
      expect(entity.shiftName, testModel.shiftName);
      expect(entity.shiftColor, testModel.shiftColor);
      expect(entity.shiftTimeWindow, testModel.shiftTimeWindow);
      expect(entity.groupName, testModel.groupName);
    });

    test('toEntityList maps a list of models to entities', () {
      final entities = AttendanceMapper.toEntityList([testModel]);

      expect(entities.length, 1);
      expect(entities.first.id, testModel.id);
    });

    test('toEntity properly sanitizes dirty data from backend DTO', () {
      const dirtyModel = AttendanceModel(
        id: '  ATT-DIRTY-99  ',
        category: '  ',
        diffMinutes: 5,
        userEmail: '  BUDI@KAWALO.ID  ',
        userName: '  Budi Santoso  ',
        userProfilePic: '  N/A  ',
        userDuty: 'null',
        attendanceDt: '1970-01-01T00:00:00.000Z',
        attendanceType: ' - ',
        latitude: '0.000000',
        longitude: '250.0', // di luar rentang bumi
        locationName: '   ',
        shiftName: '  Shift Siang  ',
        shiftColor: 'N/A',
        shiftTimeWindow: '00:00:00',
        groupName: '  Cluster Melati  ',
      );

      final entity = AttendanceMapper.toEntity(dirtyModel);

      expect(entity.id, 'ATT-DIRTY-99');
      expect(entity.category, '');
      expect(entity.userEmail, 'budi@kawalo.id');
      expect(entity.userName, 'Budi Santoso');
      expect(entity.userProfilePic, isNull);
      expect(entity.userDuty, isNull);
      expect(entity.attendanceDt, isNull);
      expect(entity.attendanceType, isNull);
      expect(entity.latitude, isNull);
      expect(entity.longitude, isNull);
      expect(entity.locationName, isNull);
      expect(entity.shiftName, 'Shift Siang');
      expect(entity.shiftColor, isNull);
      expect(entity.shiftTimeWindow, isNull);
      expect(entity.groupName, 'Cluster Melati');
    });
  });
}
