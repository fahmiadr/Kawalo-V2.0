import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_reply_model.dart';

void main() {
  test('IncidentModel.fromJson membaca kunci snake_case', () {
    final model = IncidentModel.fromJson(const {
      'id': 'inc_1',
      'group_id': 'g1',
      'title': 'Judul',
      'status': 'RESOLVED',
      'created_by': 'u1',
      'created_by_name': 'Budi',
      'resolved_by': 'u2',
      'resolved_by_name': 'Sari',
      'resolved_at': '2026-11-04T11:00:00.000Z',
      'deleted_at': '2026-11-04T12:00:00.000Z',
      'created_at': '2026-11-04T10:00:00.000Z',
      'updated_at': '2026-11-04T10:30:00.000Z',
    });

    expect(model.groupId, 'g1');
    expect(model.createdBy, 'u1');
    expect(model.createdByName, 'Budi');
    expect(model.resolvedBy, 'u2');
    expect(model.resolvedByName, 'Sari');
    expect(model.resolvedAt, '2026-11-04T11:00:00.000Z');
    expect(model.deletedAt, '2026-11-04T12:00:00.000Z');
    expect(model.createdAt, '2026-11-04T10:00:00.000Z');
    expect(model.updatedAt, '2026-11-04T10:30:00.000Z');
  });

  test('IncidentReplyModel.fromJson membaca kunci snake_case', () {
    final model = IncidentReplyModel.fromJson(const {
      'id': 'rep_1',
      'incident_id': 'inc_1',
      'sender_id': 'u1',
      'sender_name': 'Budi',
      'sender_role': 'guard',
      'message': 'Halo',
      'created_at': '2026-11-04T10:00:00.000Z',
    });

    expect(model.incidentId, 'inc_1');
    expect(model.senderId, 'u1');
    expect(model.senderName, 'Budi');
    expect(model.senderRole, 'guard');
    expect(model.createdAt, '2026-11-04T10:00:00.000Z');
  });

  test('IncidentModel.fromJson memakai default untuk kunci hilang', () {
    final model = IncidentModel.fromJson(const {
      'id': 'inc_2',
      'status': null,
      'photos': null,
      'glat': -6,
      'glong': 106.5,
    });

    expect(model.status, 'OPEN');
    expect(model.groupId, '');
    expect(model.title, '');
    expect(model.createdBy, '');
    expect(model.photos, isEmpty);
    expect(model.glat, -6.0);
    expect(model.glong, 106.5);
    expect(DateTime.tryParse(model.createdAt), isNotNull);
  });

  test('IncidentModel.toJson tidak menyertakan field opsional null', () {
    final json = IncidentModel.fromJson(const {'id': 'inc_3'}).toJson();

    expect(json.containsKey('description'), isFalse);
    expect(json.containsKey('glat'), isFalse);
    expect(json['photos'], isEmpty);
    expect(json['status'], 'OPEN');
  });

  test('IncidentReplyModel.fromJson memakai default saat kunci hilang', () {
    final model = IncidentReplyModel.fromJson(const {'id': 'r1'});

    expect(model.message, '');
    expect(model.photos, isEmpty);
    expect(DateTime.tryParse(model.createdAt), isNotNull);
  });
}
