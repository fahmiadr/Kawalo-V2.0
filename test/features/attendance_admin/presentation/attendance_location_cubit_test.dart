import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/attendance_location_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/repositories/attendance_admin_repository.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/attendance_location_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures.dart';

class MockRepository extends Mock implements AttendanceAdminRepository {}

void main() {
  late MockRepository repository;
  late AttendanceLocationCubit cubit;

  setUp(() {
    repository = MockRepository();
    cubit = AttendanceLocationCubit(repository: repository);
  });

  tearDown(() => cubit.close());

  void stubLoad(AttendanceLocationEntity location) => when(
    () => repository.getLocation(),
  ).thenAnswer((_) async => Right(location));

  void stubSave(Either<Failure, AttendanceLocationEntity> result) => when(
    () => repository.saveLocation(
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
      radius: any(named: 'radius'),
      locationName: any(named: 'locationName'),
    ),
  ).thenAnswer((_) async => result);

  test('loading an unset point starts empty with the default radius', () async {
    stubLoad(attendanceLocation());

    await cubit.load();

    expect(cubit.state.phase, AttendanceLocationPhase.loaded);
    expect(cubit.state.hasPoint, isFalse);
    expect(cubit.state.radiusText, '100');
    expect(cubit.state.isCustomRadius, isFalse);
    expect(cubit.state.isDirty, isFalse);
    expect(cubit.state.canSave, isFalse);
  });

  test('loading a configured point fills the draft', () async {
    stubLoad(attendanceLocation(configured: true, radius: 150));

    await cubit.load();

    expect(cubit.state.latitude, -6.2146);
    expect(cubit.state.locationName, 'Pos Utama');
    expect(cubit.state.radiusText, '150');
    expect(cubit.state.isCustomRadius, isTrue);
    expect(cubit.state.isDirty, isFalse);
  });

  test('a failed load shows the error and can be retried', () async {
    when(
      () => repository.getLocation(),
    ).thenAnswer((_) async => const Left(ServerFailure('Gagal.')));

    await cubit.load();

    expect(cubit.state.phase, AttendanceLocationPhase.failure);
    expect(cubit.state.errorMessage, 'Gagal.');

    stubLoad(attendanceLocation());
    await cubit.load();
    expect(cubit.state.phase, AttendanceLocationPhase.loaded);
  });

  test('picking a point on an unset location enables saving', () async {
    stubLoad(attendanceLocation());
    await cubit.load();

    cubit.setCoordinates(-6.2, 106.8);

    expect(cubit.state.isDirty, isTrue);
    expect(cubit.state.canSave, isTrue);
  });

  test('an invalid radius or the (0, 0) point blocks saving', () async {
    stubLoad(attendanceLocation());
    await cubit.load();

    cubit
      ..setCoordinates(0, 0)
      ..selectCustomRadius();
    expect(cubit.state.canSave, isFalse);

    cubit
      ..setCoordinates(-6.2, 106.8)
      ..setRadiusText('1500');
    expect(cubit.state.canSave, isFalse);
    expect(cubit.state.radiusError, 'Radius harus 10 sampai 1000 meter.');

    cubit.setRadiusText('9');
    expect(cubit.state.canSave, isFalse);

    cubit.setRadiusText('250');
    expect(cubit.state.canSave, isTrue);
    expect(cubit.state.radiusError, isNull);

    cubit.selectRadiusPreset(500);
    expect(cubit.state.isCustomRadius, isFalse);
    expect(cubit.state.radiusText, '500');
  });

  test('reverting the edits clears the dirty flag', () async {
    stubLoad(attendanceLocation(configured: true));
    await cubit.load();

    cubit.setLocationName('Pos Barat');
    expect(cubit.state.isDirty, isTrue);

    cubit.setLocationName(' Pos Utama ');
    expect(cubit.state.isDirty, isFalse);
  });

  test('save sends the draft and adopts the server answer', () async {
    stubLoad(attendanceLocation());
    await cubit.load();
    stubSave(
      Right(
        attendanceLocation(
          configured: true,
          radius: 50,
          updatedBy: 'admin@kawalo.id',
        ),
      ),
    );

    cubit
      ..setCoordinates(-6.2146, 106.8199)
      ..setLocationName(' Pos Utama ')
      ..selectRadiusPreset(50);
    await cubit.save();

    verify(
      () => repository.saveLocation(
        latitude: -6.2146,
        longitude: 106.8199,
        radius: 50,
        locationName: ' Pos Utama ',
      ),
    ).called(1);
    expect(cubit.state.saving, isFalse);
    expect(cubit.state.location?.configured, isTrue);
    expect(cubit.state.isDirty, isFalse);
    expect(cubit.state.notice, AttendanceLocationCubit.savedMessage);
    expect(cubit.state.noticeSeq, 1);
  });

  test('a failed save keeps the draft and shows the message', () async {
    stubLoad(attendanceLocation());
    await cubit.load();
    stubSave(const Left(ServerFailure('Koordinat tidak valid.', 422)));

    cubit.setCoordinates(-6.2, 106.8);
    await cubit.save();

    expect(cubit.state.latitude, -6.2);
    expect(cubit.state.isDirty, isTrue);
    expect(cubit.state.saving, isFalse);
    expect(cubit.state.notice, 'Koordinat tidak valid.');
  });

  test('save does nothing while the draft is unchanged', () async {
    stubLoad(attendanceLocation(configured: true));
    await cubit.load();

    await cubit.save();

    verifyNever(
      () => repository.saveLocation(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        radius: any(named: 'radius'),
        locationName: any(named: 'locationName'),
      ),
    );
  });
}
