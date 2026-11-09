import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/operational/data/models/operational_query_model.dart';

void main() {
  group('OperationalQueryModel Tests', () {
    test(
      'toQueryParams constructs exact snake_case parameters from fields',
      () {
        const query = OperationalQueryModel(
          search: 'Patroli',
          limit: 10,
          offset: 20,
          startDate: '2026-09-01T00:00:00.000Z',
          endDate: '2026-09-20T23:59:59.000Z',
        );

        final params = query.toQueryParams();

        expect(params['search'], 'Patroli');
        expect(params['limit'], 10);
        expect(params['offset'], 20);
        expect(params['start_date'], '2026-09-01T00:00:00.000Z');
        expect(params['end_date'], '2026-09-20T23:59:59.000Z');
      },
    );

    test('toQueryParams omits null fields and preserves exact values', () {
      const query = OperationalQueryModel(search: 'Asep');

      final params = query.toQueryParams();

      expect(params['search'], 'Asep');
      expect(params.containsKey('limit'), isFalse);
      expect(params.containsKey('offset'), isFalse);
      expect(params.containsKey('start_date'), isFalse);
      expect(params.containsKey('end_date'), isFalse);
    });

    test('props equality compares models correctly', () {
      const q1 = OperationalQueryModel(search: 'Patroli', limit: 10);
      const q2 = OperationalQueryModel(search: 'Patroli', limit: 10);
      const q3 = OperationalQueryModel(search: 'Patroli', limit: 20);

      expect(q1, equals(q2));
      expect(q1 == q3, isFalse);
    });
  });
}
