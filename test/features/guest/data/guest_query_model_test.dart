import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_query_model.dart';

void main() {
  group('GuestQueryModel Tests', () {
    test(
      'toQueryParams constructs exact snake_case parameters from fields',
      () {
        const query = GuestQueryModel(
          search: 'Bambang',
          limit: 20,
          offset: 10,
          startDate: '2026-09-01T00:00:00.000Z',
          endDate: '2026-09-20T23:59:59.000Z',
        );

        final params = query.toQueryParams();

        expect(params['search'], 'Bambang');
        expect(params['limit'], 20);
        expect(params['offset'], 10);
        expect(params['start_date'], '2026-09-01T00:00:00.000Z');
        expect(params['end_date'], '2026-09-20T23:59:59.000Z');
      },
    );

    test('toQueryParams omits null fields and preserves exact values', () {
      const query = GuestQueryModel(
        search: 'B 1234 CD',
        offset: 0,
      );

      final params = query.toQueryParams();

      expect(params['search'], 'B 1234 CD');
      expect(params['offset'], 0);
      expect(params.containsKey('limit'), isFalse);
      expect(params.containsKey('start_date'), isFalse);
      expect(params.containsKey('end_date'), isFalse);
    });

    test('props equality compares models correctly', () {
      const q1 = GuestQueryModel(search: 'Bambang', limit: 10);
      const q2 = GuestQueryModel(search: 'Bambang', limit: 10);
      const q3 = GuestQueryModel(search: 'Bambang', limit: 20);

      expect(q1, equals(q2));
      expect(q1 == q3, isFalse);
    });
  });
}
