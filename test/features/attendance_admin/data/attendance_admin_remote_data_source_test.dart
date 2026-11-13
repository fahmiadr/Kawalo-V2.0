import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/features/attendance_admin/data/datasources/attendance_admin_remote_data_source.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/manual_request_entity.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient apiClient;
  late AttendanceAdminRemoteDataSource dataSource;

  setUp(() {
    apiClient = MockApiClient();
    dataSource = AttendanceAdminRemoteDataSource(apiClient: apiClient);
  });

  test('lists requests by status with paging', () async {
    when(
      () => apiClient.get(
        '/v1/attendance/manual-requests',
        queryParameters: {'status': 'PENDING', 'limit': 20, 'offset': 40},
      ),
    ).thenAnswer(
      (_) async => {
        'data': [
          {'id': '1', 'user_name': 'A'},
          {'id': '2', 'user_name': 'B'},
        ],
      },
    );

    final models = await dataSource.getManualRequests(
      status: ManualRequestStatus.pending,
      limit: 20,
      offset: 40,
    );

    expect(models.map((m) => m.toEntity().id), ['1', '2']);
  });

  test('sends the decision action and only a non-empty note', () async {
    when(
      () => apiClient.patch(any<String>(), body: any<Object?>(named: 'body')),
    ).thenAnswer((_) async => {'success': true});

    await dataSource.decide(id: '5', approve: true, note: 'Disetujui');
    await dataSource.decide(id: '6', approve: false, note: '');

    verify(
      () => apiClient.patch(
        '/v1/attendance/manual-requests/5',
        body: {'action': 'approve', 'note': 'Disetujui'},
      ),
    ).called(1);
    verify(
      () => apiClient.patch(
        '/v1/attendance/manual-requests/6',
        body: {'action': 'reject'},
      ),
    ).called(1);
  });

  test('lists face photos with the email encoded in the path', () async {
    when(() => apiClient.get('/v1/faces/siti%40kawalo.id/photos')).thenAnswer(
      (_) async => {
        'data': [
          {'id': 'p1', 'created_at': '2026-11-10T01:00:00.000Z'},
        ],
      },
    );

    final photos = await dataSource.getFacePhotos('siti@kawalo.id');

    expect(photos.single.id, 'p1');
  });

  test('reads the setting from the envelope data', () async {
    when(() => apiClient.get('/v1/attendance/settings')).thenAnswer(
      (_) async => {
        'data': {'face_match_percent': 50, 'is_default': false},
      },
    );

    final model = await dataSource.getSetting();

    expect(model.toEntity().faceMatchPercent, 50);
  });

  test('saving sends the percent and null restores the default', () async {
    when(
      () => apiClient.put(any<String>(), body: any<Object?>(named: 'body')),
    ).thenAnswer(
      (_) async => {
        'data': {'face_match_percent': 40},
      },
    );

    await dataSource.saveSetting(60);
    await dataSource.saveSetting(null);

    verify(
      () => apiClient.put(
        '/v1/attendance/settings',
        body: {'face_match_percent': 60},
      ),
    ).called(1);
    verify(
      () => apiClient.put(
        '/v1/attendance/settings',
        body: {'face_match_percent': null},
      ),
    ).called(1);
  });

  test('reads the attendance point from the envelope data', () async {
    when(() => apiClient.get('/v1/attendance/location')).thenAnswer(
      (_) async => {
        'data': {
          'configured': true,
          'glat': -6.2,
          'glong': 106.8,
          'radius': 100,
        },
      },
    );

    final model = await dataSource.getLocation();

    expect(model.toEntity().configured, isTrue);
    expect(model.toEntity().radius, 100);
  });

  test(
    'saving the point sends a trimmed name only when it is not blank',
    () async {
      when(
        () => apiClient.put(any<String>(), body: any<Object?>(named: 'body')),
      ).thenAnswer((_) async => {'data': <String, dynamic>{}});

      await dataSource.saveLocation(
        latitude: -6.2,
        longitude: 106.8,
        radius: 50,
        locationName: ' Pos Utama ',
      );
      await dataSource.saveLocation(
        latitude: -6.2,
        longitude: 106.8,
        radius: 50,
        locationName: '   ',
      );

      verify(
        () => apiClient.put(
          '/v1/attendance/location',
          body: {
            'location_name': 'Pos Utama',
            'glat': -6.2,
            'glong': 106.8,
            'radius': 50,
          },
        ),
      ).called(1);
      verify(
        () => apiClient.put(
          '/v1/attendance/location',
          body: {'glat': -6.2, 'glong': 106.8, 'radius': 50},
        ),
      ).called(1);
    },
  );
}
