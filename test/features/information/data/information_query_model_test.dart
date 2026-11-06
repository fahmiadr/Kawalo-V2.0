import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/information/data/models/information_query_model.dart';

void main() {
  group('InformationQueryModel Tests', () {
    test(
      'toQueryParams constructs exact snake_case parameters from fields',
      () {
        const query = InformationQueryModel(
          search: 'Posko',
          limit: 15,
          offset: 5,
          startDate: '2026-09-01T00:00:00.000Z',
          endDate: '2026-09-20T23:59:59.000Z',
        );

        final params = query.toQueryParams();

        expect(params['search'], 'Posko');
        expect(params['limit'], 15);
        expect(params['offset'], 5);
        expect(params['start_date'], '2026-09-01T00:00:00.000Z');
        expect(params['end_date'], '2026-09-20T23:59:59.000Z');
      },
    );

    test('toQueryParams omits null fields and preserves exact values', () {
      const query = InformationQueryModel(
        search: 'Laporan Air',
        limit: 10,
      );

      final params = query.toQueryParams();

      expect(params['search'], 'Laporan Air');
      expect(params['limit'], 10);
      expect(params.containsKey('offset'), isFalse);
      expect(params.containsKey('start_date'), isFalse);
      expect(params.containsKey('end_date'), isFalse);
    });

    test('props equality compares models correctly', () {
      const q1 = InformationQueryModel(search: 'Info', limit: 10);
      const q2 = InformationQueryModel(search: 'Info', limit: 10);
      const q3 = InformationQueryModel(search: 'Info', limit: 20);

      expect(q1, equals(q2));
      expect(q1 == q3, isFalse);
    });
  });
}
