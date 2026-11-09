import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/incident/data/mappers/incident_local_mapper.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_model.dart';

void main() {
  group('IncidentLocalMapper Tests', () {
    const testModel = IncidentModel(
      id: 'inc_1',
      groupId: 'grp_1',
      title: '  Pintu Rusak  ',
      description: 'Gerbang utara macet',
      category: 'facility',
      glat: -6.2,
      glong: 106.8,
      photos: ['a.jpg', ' ', 'b.jpg'],
      status: 'RESOLVED',
      createdBy: 'usr_1',
      createdByName: 'Budi',
      resolvedBy: 'usr_2',
      resolvedByName: 'Dewi',
      resolvedAt: '2026-11-05T10:00:00.000Z',
      createdAt: '2026-11-04T10:00:00.000Z',
      updatedAt: '2026-11-05T10:00:00.000Z',
    );

    test('toLocal sanitizes text and keeps every field', () {
      final local = IncidentLocalMapper.toLocal(testModel);

      expect(local.id, 'inc_1');
      expect(local.groupId, 'grp_1');
      expect(local.title, 'Pintu Rusak');
      expect(local.description, 'Gerbang utara macet');
      expect(local.category, 'facility');
      expect(local.glat, -6.2);
      expect(local.glong, 106.8);
      expect(local.photos, ['a.jpg', 'b.jpg']);
      expect(local.status, 'RESOLVED');
      expect(local.createdBy, 'usr_1');
      expect(local.createdByName, 'Budi');
      expect(local.resolvedBy, 'usr_2');
      expect(local.resolvedByName, 'Dewi');
      expect(local.resolvedAt, '2026-11-05T10:00:00.000Z');
      expect(local.createdAt, '2026-11-04T10:00:00.000Z');
      expect(local.updatedAt, '2026-11-05T10:00:00.000Z');
    });

    test('toLocal normalizes createdAt to UTC for lexicographic compare', () {
      final local = IncidentLocalMapper.toLocal(
        const IncidentModel(
          id: 'inc_2',
          groupId: 'grp_1',
          title: 'Lampu',
          status: 'OPEN',
          createdBy: 'usr_1',
          createdAt: '2026-11-04T17:00:00.000+07:00',
        ),
      );

      expect(local.createdAt, '2026-11-04T10:00:00.000Z');
    });

    test('fromLocal(toLocal(x)) round-trips the sanitized model', () {
      final roundTrip = IncidentLocalMapper.fromLocal(
        IncidentLocalMapper.toLocal(testModel),
      );

      expect(roundTrip.id, testModel.id);
      expect(roundTrip.title, 'Pintu Rusak');
      expect(roundTrip.photos, ['a.jpg', 'b.jpg']);
      expect(roundTrip.status, testModel.status);
      expect(roundTrip.createdAt, testModel.createdAt);
      expect(roundTrip.resolvedByName, testModel.resolvedByName);
    });

    test('list helpers map every element', () {
      final locals = IncidentLocalMapper.toLocalList([testModel, testModel]);
      expect(locals, hasLength(2));
      expect(IncidentLocalMapper.fromLocalList(locals), hasLength(2));
    });
  });
}
