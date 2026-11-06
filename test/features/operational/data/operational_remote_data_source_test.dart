import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/features/operational/data/datasources/operational_remote_data_source.dart';
import 'package:kawalo_mobile/features/operational/data/models/operational_query_model.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late OperationalRemoteDataSourceImpl dataSource;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = OperationalRemoteDataSourceImpl(apiClient: mockApiClient);
  });

  const sampleJsonItem = {
    'id': 'agus@kawalo.id_2026-09-25',
    'user_email': 'agus@kawalo.id',
    'user_name': 'Agus Setiawan',
    'user_profile_pic': 'https://example.com/photo.png',
    'group_name': 'JKN Veranda',
    'latest_duty': 'Patroli Lingkungan',
    'latest_state': 'Aktif',
    'latest_duty_dt': '2026-09-25T08:30:00.000Z',
    'latest_state_dt': '2026-09-25T08:35:00.000Z',
    'total_activities': 4,
    'duty_date': '2026-09-25',
    'timeline': [
      {
        'id': '101',
        'journey_uid': 'JRN-001',
        'duty': 'Patroli Lingkungan',
        'state': 'Aktif',
        'duty_dt': '2026-09-25T08:30:00.000Z',
        'state_dt': '2026-09-25T08:35:00.000Z',
      },
    ],
  };

  group('OperationalRemoteDataSourceImpl Tests', () {
    test(
      'getOperationals constructs exact query parameters and parses response',
      () async {
        when(
          () => mockApiClient.get(
            '/v1/operational',
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => {
            'success': true,
            'message': 'Daftar personil operasional berhasil diambil',
            'data': [sampleJsonItem],
          },
        );

        const query = OperationalQueryModel(
          search: 'Agus',
          limit: 20,
          offset: 0,
          startDate: '2026-09-01T00:00:00.000Z',
          endDate: '2026-09-25T23:59:59.000Z',
        );

        final result = await dataSource.getOperationals(query: query);

        expect(result.length, 1);
        final item = result.first;
        expect(item.userEmail, 'agus@kawalo.id');
        expect(item.userName, 'Agus Setiawan');
        expect(item.groupName, 'JKN Veranda');
        expect(item.latestDuty, 'Patroli Lingkungan');
        expect(item.totalActivities, 4);
        expect(item.timeline.length, 1);
        expect(item.timeline.first.id, '101');

        verify(
          () => mockApiClient.get(
            '/v1/operational',
            queryParameters: {
              'search': 'Agus',
              'limit': 20,
              'offset': 0,
              'start_date': '2026-09-01T00:00:00.000Z',
              'end_date': '2026-09-25T23:59:59.000Z',
            },
          ),
        ).called(1);
      },
    );

    test('getOperationals handles empty or missing data gracefully', () async {
      when(
        () => mockApiClient.get(
          '/v1/operational',
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

      final result = await dataSource.getOperationals(
        query: const OperationalQueryModel(),
      );

      expect(result, isEmpty);
      verify(
        () => mockApiClient.get(
          '/v1/operational',
          queryParameters: <String, dynamic>{},
        ),
      ).called(1);
    });
  });
}
