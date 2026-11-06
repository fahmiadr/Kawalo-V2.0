import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:kawalo_mobile/features/attendance/data/models/attendance_query_model.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late AttendanceRemoteDataSourceImpl dataSource;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = AttendanceRemoteDataSourceImpl(apiClient: mockApiClient);
  });

  const sampleJsonItem = {
    'id': 'att_001',
    'user_email': 'guard1@kawalo.id',
    'user_name': 'Agus Guard',
    'user_profile_pic': 'https://example.com/photo.png',
    'user_duty': 'ON DUTY',
    'attendance_dt': '2026-09-20T08:00:00.000Z',
    'attendance_type': 'Absen Masuk Shift Pagi',
    'category': 'MASUK',
    'latitude': '-6.200000',
    'longitude': '106.816666',
    'diff_minutes': 0,
    'location_name': 'Pos Utama',
    'shift_name': 'Shift Pagi',
    'shift_color': '#10B981',
    'shift_time_window': '08:00 - 16:00',
    'group_uid': 'GRP-KIERA',
    'group_name': 'Cluster Kiera',
  };

  group('AttendanceRemoteDataSourceImpl Tests', () {
    test(
      'getAttendances constructs exact query parameters and parses response',
      () async {
        when(
          () => mockApiClient.get(
            '/v1/attendance',
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => {
            'success': true,
            'message': 'Daftar data absensi berhasil diambil',
            'data': [sampleJsonItem],
          },
        );

        const query = AttendanceQueryModel(
          search: 'Agus',
          limit: 20,
          offset: 0,
          startDate: '2026-09-01T00:00:00.000Z',
          endDate: '2026-09-20T23:59:59.000Z',
        );

        final result = await dataSource.getAttendances(query: query);

        expect(result.length, 1);
        final item = result.first;
        expect(item.id, 'att_001');
        expect(item.userEmail, 'guard1@kawalo.id');
        expect(item.userName, 'Agus Guard');
        expect(item.category, 'MASUK');
        expect(item.diffMinutes, 0);
        expect(item.locationName, 'Pos Utama');
        expect(item.groupName, 'Cluster Kiera');

        verify(
          () => mockApiClient.get(
            '/v1/attendance',
            queryParameters: {
              'search': 'Agus',
              'limit': 20,
              'offset': 0,
              'start_date': '2026-09-01T00:00:00.000Z',
              'end_date': '2026-09-20T23:59:59.000Z',
            },
          ),
        ).called(1);
      },
    );

    test('getAttendances handles empty or missing data gracefully', () async {
      when(
        () => mockApiClient.get(
          '/v1/attendance',
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'message': 'Data kosong',
          'data': <dynamic>[],
        },
      );

      final result = await dataSource.getAttendances(
        query: const AttendanceQueryModel(),
      );

      expect(result, isEmpty);
      verify(
        () => mockApiClient.get(
          '/v1/attendance',
          queryParameters: <String, dynamic>{},
        ),
      ).called(1);
    });
  });
}
