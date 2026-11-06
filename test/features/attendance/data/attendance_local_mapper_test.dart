import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/attendance/data/mappers/attendance_local_mapper.dart';
import 'package:kawalo_mobile/features/attendance/data/models/attendance_local_model.dart';
import 'package:kawalo_mobile/features/attendance/data/models/attendance_model.dart';

void main() {
  group('AttendanceLocalMapper Tests', () {
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

    test('toLocal maps AttendanceModel to AttendanceLocalModel', () {
      final collection = AttendanceLocalMapper.toLocal(testModel);

      expect(collection, isA<AttendanceLocalModel>());
      expect(collection.id, testModel.id);
      expect(collection.category, testModel.category);
      expect(collection.diffMinutes, testModel.diffMinutes);
      expect(collection.userEmail, testModel.userEmail);
      expect(collection.userName, testModel.userName);
      expect(collection.userProfilePic, testModel.userProfilePic);
      expect(collection.userDuty, testModel.userDuty);
      expect(collection.attendanceDt, testModel.attendanceDt);
      expect(collection.attendanceType, testModel.attendanceType);
      expect(collection.latitude, testModel.latitude);
      expect(collection.longitude, testModel.longitude);
      expect(collection.locationName, testModel.locationName);
      expect(collection.shiftName, testModel.shiftName);
      expect(collection.shiftColor, testModel.shiftColor);
      expect(collection.shiftTimeWindow, testModel.shiftTimeWindow);
      expect(collection.groupName, testModel.groupName);
    });

    test('fromLocal maps AttendanceLocalModel to AttendanceModel', () {
      final collection = AttendanceLocalMapper.toLocal(testModel);
      final model = AttendanceLocalMapper.fromLocal(collection);

      expect(model.id, testModel.id);
      expect(model.category, testModel.category);
      expect(model.diffMinutes, testModel.diffMinutes);
      expect(model.userEmail, testModel.userEmail);
      expect(model.userName, testModel.userName);
      expect(model.shiftTimeWindow, testModel.shiftTimeWindow);
      expect(model.groupName, testModel.groupName);
    });

    test('toLocalList and fromLocalList map collections round-trip', () {
      final collections = AttendanceLocalMapper.toLocalList([testModel]);
      expect(collections.length, 1);
      expect(collections.first.id, testModel.id);

      final models = AttendanceLocalMapper.fromLocalList(collections);
      expect(models.length, 1);
      expect(models.first.id, testModel.id);
    });

    test('toLocal and fromLocal sanitize dirty data correctly', () {
      const dirtyModel = AttendanceModel(
        id: '  ATT-LOCAL-DIRTY  ',
        category: '  ',
        diffMinutes: 0,
        userEmail: '  JOHN.DOE@KAWALO.ID  ',
        userName: '  John Doe  ',
        userProfilePic: 'N/A',
        userDuty: 'null',
        attendanceDt: '0000-00-00 00:00:00',
        attendanceType: ' - ',
        latitude: '0.0',
        longitude: '106.8456',
        locationName: '  Pos Timur  ',
        shiftName: '  Shift Malam  ',
        shiftColor: 'null',
        shiftTimeWindow: '00:00:00',
        groupName: '   ',
      );

      final local = AttendanceLocalMapper.toLocal(dirtyModel);
      expect(local.id, 'ATT-LOCAL-DIRTY');
      expect(local.category, '');
      expect(local.userEmail, 'john.doe@kawalo.id');
      expect(local.userName, 'John Doe');
      expect(local.userProfilePic, isNull);
      expect(local.userDuty, isNull);
      expect(local.attendanceDt, isNull);
      expect(local.attendanceType, isNull);
      expect(local.latitude, isNull);
      expect(local.longitude, '106.8456');
      expect(local.locationName, 'Pos Timur');
      expect(local.shiftName, 'Shift Malam');
      expect(local.shiftColor, isNull);
      expect(local.shiftTimeWindow, isNull);
      expect(local.groupName, isNull);

      final roundTrip = AttendanceLocalMapper.fromLocal(local);
      expect(roundTrip.id, 'ATT-LOCAL-DIRTY');
      expect(roundTrip.category, '');
      expect(roundTrip.userEmail, 'john.doe@kawalo.id');
      expect(roundTrip.userName, 'John Doe');
      expect(roundTrip.userProfilePic, isNull);
      expect(roundTrip.locationName, 'Pos Timur');
      expect(roundTrip.latitude, isNull);
      expect(roundTrip.longitude, '106.8456');
    });
  });
}
