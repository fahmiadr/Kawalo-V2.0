import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';

void main() {
  group('Operational Domain Entities Tests', () {
    group('DutyTimelineEntity', () {
      test('props equality compares identical entities as equal', () {
        const item1 = DutyTimelineEntity(
          id: '1',
          journeyUid: 'JRN-01',
          duty: 'Patroli',
          state: 'Aktif',
          dutyDt: '2026-09-25T08:00:00.000Z',
          stateDt: '2026-09-25T08:05:00.000Z',
        );
        const item2 = DutyTimelineEntity(
          id: '1',
          journeyUid: 'JRN-01',
          duty: 'Patroli',
          state: 'Aktif',
          dutyDt: '2026-09-25T08:00:00.000Z',
          stateDt: '2026-09-25T08:05:00.000Z',
        );
        const item3 = DutyTimelineEntity(
          id: '2',
          journeyUid: 'JRN-02',
          duty: 'Standby',
          state: 'Siaga',
        );

        expect(item1, equals(item2));
        expect(item1 == item3, isFalse);
      });
    });

    group('OperationalItemEntity', () {
      test('props equality compares identical entities as equal', () {
        const worker1 = OperationalItemEntity(
          id: 'agus@kawalo.id_2026-09-10',
          userEmail: 'agus@kawalo.id',
          userName: 'Agus Setiawan',
          totalActivities: 2,
          timeline: [
            DutyTimelineEntity(id: '1', duty: 'Patroli'),
          ],
        );
        const worker2 = OperationalItemEntity(
          id: 'agus@kawalo.id_2026-09-10',
          userEmail: 'agus@kawalo.id',
          userName: 'Agus Setiawan',
          totalActivities: 2,
          timeline: [
            DutyTimelineEntity(id: '1', duty: 'Patroli'),
          ],
        );
        const worker3 = OperationalItemEntity(
          id: 'hendra@kawalo.id_2026-09-10',
          userEmail: 'hendra@kawalo.id',
          userName: 'Hendra Pratama',
          totalActivities: 1,
          timeline: [],
        );

        expect(worker1, equals(worker2));
        expect(worker1 == worker3, isFalse);
      });
    });
  });
}
