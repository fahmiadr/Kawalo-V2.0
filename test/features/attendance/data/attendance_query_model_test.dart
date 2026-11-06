import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/attendance/data/models/attendance_query_model.dart';

void main() {
  group('AttendanceQueryModel Tests', () {
    test(
      'toQueryParams constructs exact snake_case parameters from fields',
      () {
        const query = AttendanceQueryModel(
          search: 'Budi Santoso',
          limit: 15,
          offset: 30,
          startDate: '2026-09-01T00:00:00.000Z',
          endDate: '2026-09-20T23:59:59.000Z',
        );

        final params = query.toQueryParams();

        expect(params['search'], 'Budi Santoso');
        expect(params['limit'], 15);
        expect(params['offset'], 30);
        expect(params['start_date'], '2026-09-01T00:00:00.000Z');
        expect(params['end_date'], '2026-09-20T23:59:59.000Z');
      },
    );

    test('toQueryParams omits null fields and preserves search value', () {
      const query = AttendanceQueryModel(
        search: 'raw query',
        offset: 0,
      );

      final params = query.toQueryParams();

      expect(params['search'], 'raw query');
      expect(params['offset'], 0);
      expect(params.containsKey('limit'), isFalse);
      expect(params.containsKey('start_date'), isFalse);
      expect(params.containsKey('end_date'), isFalse);
    });

    test('toQueryParams omits search key when search is null', () {
      const emptyQuery = AttendanceQueryModel();

      expect(emptyQuery.toQueryParams().containsKey('search'), isFalse);
    });

    test('props equality compares models correctly', () {
      const q1 = AttendanceQueryModel(search: 'Ahmad', limit: 10);
      const q2 = AttendanceQueryModel(search: 'Ahmad', limit: 10);
      const q3 = AttendanceQueryModel(search: 'Ahmad', limit: 20);

      expect(q1, equals(q2));
      expect(q1 == q3, isFalse);
    });
  });
}
