import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/incident/data/models/create_incident_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_reply_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/post_incident_reply_model.dart';

void main() {
  group('CreateIncidentModel.toJson', () {
    test('keeps required keys and empty photos when optionals are null', () {
      expect(const CreateIncidentModel(title: 'T', groupId: 'g').toJson(), {
        'title': 'T',
        'group_id': 'g',
        'photos': <String>[],
      });
    });

    test('includes every optional key when set', () {
      expect(
        const CreateIncidentModel(
          title: 'T',
          groupId: 'g',
          description: 'd',
          category: 'FIRE',
          glat: -6.2,
          glong: 106.8,
          photos: ['a'],
        ).toJson(),
        {
          'title': 'T',
          'group_id': 'g',
          'description': 'd',
          'category': 'FIRE',
          'glat': -6.2,
          'glong': 106.8,
          'photos': ['a'],
        },
      );
    });

    test('includes only the optional keys that are set', () {
      expect(
        const CreateIncidentModel(
          title: 'T',
          groupId: 'g',
          category: 'FIRE',
          glong: 106.8,
        ).toJson(),
        {
          'title': 'T',
          'group_id': 'g',
          'category': 'FIRE',
          'glong': 106.8,
          'photos': <String>[],
        },
      );
    });
  });

  test('PostIncidentReplyModel.toJson always sends photos', () {
    expect(const PostIncidentReplyModel(message: 'm').toJson(), {
      'message': 'm',
      'photos': <String>[],
    });
    expect(const PostIncidentReplyModel(message: 'm', photos: ['a']).toJson(), {
      'message': 'm',
      'photos': ['a'],
    });
  });

  group('IncidentModel.toJson', () {
    test('omits null optionals', () {
      expect(
        const IncidentModel(
          id: '1',
          groupId: 'g',
          title: 'T',
          status: 'OPEN',
          createdBy: 'u',
          createdAt: '2026-01-01T00:00:00Z',
        ).toJson(),
        {
          'id': '1',
          'group_id': 'g',
          'title': 'T',
          'photos': <String>[],
          'status': 'OPEN',
          'created_by': 'u',
          'created_at': '2026-01-01T00:00:00Z',
        },
      );
    });

    test('includes every key when set', () {
      expect(
        const IncidentModel(
          id: '1',
          groupId: 'g',
          title: 'T',
          status: 'RESOLVED',
          createdBy: 'u',
          createdAt: 'c',
          createdByName: 'Un',
          description: 'd',
          category: 'FIRE',
          glat: -6.2,
          glong: 106.8,
          photos: ['a'],
          resolvedBy: 'r',
          resolvedByName: 'Rn',
          resolvedAt: 'ra',
          deletedAt: 'da',
          updatedAt: 'ua',
        ).toJson(),
        {
          'id': '1',
          'group_id': 'g',
          'title': 'T',
          'description': 'd',
          'category': 'FIRE',
          'glat': -6.2,
          'glong': 106.8,
          'photos': ['a'],
          'status': 'RESOLVED',
          'created_by': 'u',
          'created_by_name': 'Un',
          'resolved_by': 'r',
          'resolved_by_name': 'Rn',
          'resolved_at': 'ra',
          'deleted_at': 'da',
          'created_at': 'c',
          'updated_at': 'ua',
        },
      );
    });

    test('includes only the optional keys that are set', () {
      expect(
        const IncidentModel(
          id: '1',
          groupId: 'g',
          title: 'T',
          status: 'OPEN',
          createdBy: 'u',
          createdAt: 'c',
          glat: 1.5,
          deletedAt: 'da',
        ).toJson(),
        {
          'id': '1',
          'group_id': 'g',
          'title': 'T',
          'glat': 1.5,
          'photos': <String>[],
          'status': 'OPEN',
          'created_by': 'u',
          'deleted_at': 'da',
          'created_at': 'c',
        },
      );
    });
  });

  test('IncidentReplyModel.toJson emits every field', () {
    expect(
      const IncidentReplyModel(
        id: '1',
        incidentId: 'i',
        senderId: 's',
        senderName: 'S',
        senderRole: 'admin',
        message: 'm',
        createdAt: 'c',
        photos: ['a'],
      ).toJson(),
      {
        'id': '1',
        'incident_id': 'i',
        'sender_id': 's',
        'sender_name': 'S',
        'sender_role': 'admin',
        'message': 'm',
        'photos': ['a'],
        'created_at': 'c',
      },
    );
  });
}
