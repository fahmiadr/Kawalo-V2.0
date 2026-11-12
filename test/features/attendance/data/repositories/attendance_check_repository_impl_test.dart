import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/attendance/data/datasources/attendance_check_remote_data_source.dart';
import 'package:kawalo_mobile/features/attendance/data/repositories/attendance_check_repository_impl.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_check_result.dart';
import 'package:kawalo_mobile/features/attendance/domain/repositories/attendance_check_repository.dart';
import 'package:kawalo_mobile/features/face/data/datasources/face_multipart.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements AttendanceCheckRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late AttendanceCheckRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(Uint8List(0)));

  setUp(() {
    remote = _MockRemote();
    repository = AttendanceCheckRepositoryImpl(remoteDataSource: remote);
  });

  void submitThrows(Object error) => when(
    () => remote.submit(
      photo: any(named: 'photo'),
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
      nonce: any(named: 'nonce'),
    ),
  ).thenThrow(error);

  Future<Failure> submitFailure() async => (await repository.submit(
    photo: Uint8List(1),
    latitude: 0,
    longitude: 0,
    nonce: 'n',
  )).getLeft().toNullable()!;

  ServerExceptionWithBody notMatch(Map<String, dynamic> body) =>
      ServerExceptionWithBody(
        const ServerException('Tidak cocok.', 403, 'FACE_NOT_MATCH'),
        body,
      );

  test('reads the failure count at the top level of the envelope', () async {
    submitThrows(
      notMatch({'failed_attempts': 3, 'manual_request_available': true}),
    );
    expect(
      await submitFailure(),
      const FaceNotMatchFailure(
        'Tidak cocok.',
        failedAttempts: 3,
        manualRequestAvailable: true,
      ),
    );
  });

  test('also finds the count inside details', () async {
    submitThrows(
      notMatch({
        'details': {'failed_attempts': 1, 'manual_request_available': false},
      }),
    );
    final failure = await submitFailure() as FaceNotMatchFailure;
    expect(failure.failedAttempts, 1);
    expect(failure.manualRequestAvailable, isFalse);
  });

  test('keeps other codes as plain server failures', () async {
    submitThrows(
      ServerExceptionWithBody(
        const ServerException('Jauh.', 403, 'ATTENDANCE_OUT_OF_RADIUS'),
        const {},
      ),
    );
    expect(
      await submitFailure(),
      const ServerFailure('Jauh.', 403, 'ATTENDANCE_OUT_OF_RADIUS'),
    );
  });

  test('parses the check result', () {
    final result = AttendanceCheckRemoteDataSource.parseCheckResult({
      'id': '7',
      'attendance_type': 'CHECK OUT',
      'category': 'pulang',
      'attendance_dt': '2026-11-12T07:20:00Z',
      'status': 'early_leave',
      'late_minutes': 0,
      'early_leave_minutes': 40,
      'shift_name': 'Shift Pagi',
      'shift_time_window': '07:00 - 15:00',
      'location_name': 'Lobby',
      'distance_meters': 38,
    });
    expect(result.isCheckIn, isFalse);
    expect(result.status, AttendanceCheckStatus.earlyLeave);
    expect(result.isWarning, isTrue);
    expect(result.earlyLeaveMinutes, 40);
    expect(result.distanceMeters, 38);
    expect(result.attendanceAt.isUtc, isFalse);
  });

  test('parses the failure tally from the nonce response', () {
    final nonce = AttendanceCheckRemoteDataSource.parseNonce({
      'nonce': 'abc',
      'failed_attempts': 4,
      'manual_request_available': true,
    });
    expect(nonce.value, 'abc');
    expect(nonce.failedAttempts, 4);
    expect(nonce.manualRequestAvailable, isTrue);
    expect(
      AttendanceCheckRemoteDataSource.parseNonce({
        'nonce': 'x',
      }).manualRequestAvailable,
      isNull,
    );
  });
}
