import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/features/attendance/stats/attendance_stats.dart';
import 'package:kawalo_mobile/features/attendance/stats/attendance_stats_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient apiClient;
  late AttendanceStatsRepositoryImpl repository;

  setUp(() {
    apiClient = MockApiClient();
    repository = AttendanceStatsRepositoryImpl(apiClient: apiClient);
  });

  test('requests the range and parses the counts', () async {
    when(
      () => apiClient.get(
        '/v1/attendance/stats',
        queryParameters: {'from': '2026-11-01', 'to': '2026-11-12'},
      ),
    ).thenAnswer(
      (_) async => {
        'success': true,
        'data': {
          'from': '2026-11-01',
          'to': '2026-11-12',
          'total': 7,
          'check_in': 3,
          'check_out': 2,
          'other': 2,
          'late': 1,
          'early_leave': 1,
        },
      },
    );

    final result = await repository.getStats(
      from: '2026-11-01',
      to: '2026-11-12',
    );

    expect(
      result.toNullable(),
      const AttendanceStats(
        total: 7,
        checkIn: 3,
        checkOut: 2,
        late: 1,
        earlyLeave: 1,
      ),
    );
  });

  test('maps an API error to a failure', () async {
    when(
      () =>
          apiClient.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenThrow(const ServerException('Rentang tanggal maksimal 92 hari', 422));

    final result = await repository.getStats(from: 'a', to: 'b');

    expect(result.isLeft(), isTrue);
    expect(
      result.getLeft().toNullable()?.message,
      'Rentang tanggal maksimal 92 hari',
    );
  });
}
