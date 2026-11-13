import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/features/attendance/photo/authenticated_photo_fetcher.dart';
import 'package:kawalo_mobile/features/attendance_admin/data/datasources/attendance_admin_remote_data_source.dart';
import 'package:kawalo_mobile/features/attendance_admin/data/models/attendance_location_model.dart';
import 'package:kawalo_mobile/features/attendance_admin/data/models/attendance_setting_model.dart';
import 'package:kawalo_mobile/features/attendance_admin/data/models/manual_request_model.dart';
import 'package:kawalo_mobile/features/attendance_admin/data/repositories/attendance_admin_repository_impl.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/manual_request_entity.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements AttendanceAdminRemoteDataSource {}

class MockFetcher extends Mock implements AuthenticatedPhotoFetcher {}

void main() {
  late MockRemote remote;
  late MockFetcher fetcher;
  late AttendanceAdminRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(ManualRequestStatus.pending));

  setUp(() {
    remote = MockRemote();
    fetcher = MockFetcher();
    repository = AttendanceAdminRepositoryImpl(
      remoteDataSource: remote,
      photoFetcher: fetcher,
    );
  });

  test('maps models to entities', () async {
    when(
      () => remote.getManualRequests(
        status: any(named: 'status'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer(
      (_) async => [
        const ManualRequestModel({'id': '5', 'status': 'PENDING'}),
      ],
    );

    final result = await repository.getManualRequests(
      status: ManualRequestStatus.pending,
      limit: 20,
      offset: 0,
    );

    expect(result.toNullable()?.single.id, '5');
  });

  test('a server error becomes a failure with its message', () async {
    when(
      () => remote.decide(
        id: any(named: 'id'),
        approve: any(named: 'approve'),
        note: any(named: 'note'),
      ),
    ).thenThrow(const ServerException('Permintaan ini sudah diputuskan.', 409));

    final result = await repository.decideManualRequest(id: '5', approve: true);

    expect(
      result.getLeft().toNullable()?.message,
      'Permintaan ini sudah diputuskan.',
    );
  });

  test('face photos are fetched from the protected endpoint', () async {
    when(
      () => fetcher.fetch(any(), name: any(named: 'name')),
    ).thenAnswer((_) async => const Right('/tmp/p.jpg'));

    final result = await repository.downloadFacePhoto(
      email: 'siti@kawalo.id',
      photoId: 'p1',
    );

    expect(result.toNullable(), '/tmp/p.jpg');
    verify(
      () => fetcher.fetch(
        '/v1/faces/siti%40kawalo.id/photos/p1',
        name: any(named: 'name'),
      ),
    ).called(1);
  });

  test('maps the saved setting to an entity', () async {
    when(() => remote.saveSetting(55)).thenAnswer(
      (_) async => const AttendanceSettingModel({'face_match_percent': 55}),
    );

    final result = await repository.saveSetting(55);

    expect(result.toNullable()?.faceMatchPercent, 55);
  });

  test('an out of range save becomes a failure with the 422 message', () async {
    when(() => remote.saveSetting(any())).thenThrow(
      const ServerException('Persentase harus antara 20 dan 95.', 422),
    );

    final result = await repository.saveSetting(10);

    expect(result.getLeft().toNullable()?.message, contains('antara 20'));
    expect(result.getLeft().toNullable()?.statusCode, 422);
  });

  test('a failed load becomes a failure', () async {
    when(() => remote.getSetting()).thenThrow(
      const ServerException('Hanya admin yang dapat mengakses.', 403),
    );

    final result = await repository.getSetting();

    expect(result.isLeft(), isTrue);
  });

  test('maps the loaded attendance point to an entity', () async {
    when(() => remote.getLocation()).thenAnswer(
      (_) async => const AttendanceLocationModel({
        'configured': true,
        'glat': -6.2,
        'glong': 106.8,
        'radius': 120,
      }),
    );

    final result = await repository.getLocation();

    expect(result.toNullable()?.configured, isTrue);
    expect(result.toNullable()?.radius, 120);
  });

  test('saving the point forwards the values', () async {
    when(
      () => remote.saveLocation(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        radius: any(named: 'radius'),
        locationName: any(named: 'locationName'),
      ),
    ).thenAnswer(
      (_) async => const AttendanceLocationModel({
        'configured': true,
        'glat': -6.2,
        'glong': 106.8,
        'radius': 50,
      }),
    );

    final result = await repository.saveLocation(
      latitude: -6.2,
      longitude: 106.8,
      radius: 50,
      locationName: 'Pos',
    );

    expect(result.isRight(), isTrue);
    verify(
      () => remote.saveLocation(
        latitude: -6.2,
        longitude: 106.8,
        radius: 50,
        locationName: 'Pos',
      ),
    ).called(1);
  });

  test('a rejected point save becomes a failure with the 403 status', () async {
    when(
      () => remote.saveLocation(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        radius: any(named: 'radius'),
        locationName: any(named: 'locationName'),
      ),
    ).thenThrow(const ServerException('Hanya admin yang dapat mengubah.', 403));

    final result = await repository.saveLocation(
      latitude: -6.2,
      longitude: 106.8,
      radius: 50,
    );

    expect(result.getLeft().toNullable()?.statusCode, 403);
  });
}
