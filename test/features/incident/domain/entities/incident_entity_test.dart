import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';

void main() {
  group('IncidentEntity Authorization & Status Tests', () {
    final tIncident = IncidentEntity(
      id: 'inc_1',
      groupId: 'grp_sakura',
      title: 'Pintu Gerbang Rusak',
      status: IncidentStatus.open,
      createdBy: 'usr_guard',
      createdAt: DateTime.parse('2026-11-04T10:00:00.000Z'),
    );

    const guardSession = AuthSessionEntity(
      userId: 'usr_guard',
      email: 'guard@kawalo.id',
      name: 'Budi Santoso',
      allowAdmin: false,
      allowPatrol: true,
      allowMonPatrol: false,
      groupUid: 'grp_sakura',
    );

    const otherGroupGuardSession = AuthSessionEntity(
      userId: 'usr_other',
      email: 'other@kawalo.id',
      name: 'Joko',
      allowAdmin: false,
      allowPatrol: true,
      allowMonPatrol: false,
      groupUid: 'grp_mawar',
    );

    const adminSession = AuthSessionEntity(
      userId: 'usr_admin',
      email: 'admin@kawalo.id',
      name: 'Dewi Sartika',
      allowAdmin: true,
      allowPatrol: false,
      allowMonPatrol: true,
      groupUid: 'grp_mawar',
    );

    test('canBeCreatedBySession returns true when groupUid is present', () {
      expect(IncidentEntity.canBeCreatedBySession(guardSession), isTrue);
      expect(IncidentEntity.canBeCreatedBySession(null), isFalse);
      const noGroupSession = AuthSessionEntity(
        userId: 'u1',
        email: 'u1@k.id',
        name: 'No Group',
        allowAdmin: false,
        allowPatrol: false,
        allowMonPatrol: false,
        groupUid: '',
      );
      expect(IncidentEntity.canBeCreatedBySession(noGroupSession), isFalse);
    });

    test('canBeViewedBySession enforces group match, even for admins', () {
      expect(tIncident.canBeViewedBySession(guardSession), isTrue);
      expect(tIncident.canBeViewedBySession(otherGroupGuardSession), isFalse);
      expect(tIncident.canBeViewedBySession(adminSession), isFalse);
      expect(
        tIncident.canBeViewedBySession(
          const AuthSessionEntity(
            userId: 'usr_admin',
            email: 'admin@kawalo.id',
            name: 'Dewi Sartika',
            allowAdmin: true,
            allowPatrol: false,
            allowMonPatrol: true,
            groupUid: 'grp_sakura',
          ),
        ),
        isTrue,
      );
      expect(tIncident.canBeViewedBySession(null), isFalse);
    });

    test('canReplyBySession allows active thread replies only', () {
      expect(tIncident.canReplyBySession(guardSession), isTrue);
      expect(tIncident.canReplyBySession(otherGroupGuardSession), isFalse);

      final resolvedIncident = tIncident.copyWith(
        status: IncidentStatus.resolved,
      );
      expect(resolvedIncident.canReplyBySession(guardSession), isFalse);

      final deletedIncident = tIncident.copyWith(deletedAt: DateTime.now());
      expect(deletedIncident.canReplyBySession(guardSession), isFalse);
    });

    test('canBeResolvedBySession allows resolution on open incident', () {
      expect(tIncident.canBeResolvedBySession(guardSession), isTrue);
      expect(tIncident.canBeResolvedBySession(adminSession), isFalse);
      expect(tIncident.canBeResolvedBySession(otherGroupGuardSession), isFalse);

      final resolvedIncident = tIncident.copyWith(
        status: IncidentStatus.resolved,
      );
      expect(resolvedIncident.canBeResolvedBySession(guardSession), isFalse);
    });

    test('canBeDeletedBySession allows only administrators', () {
      expect(tIncident.canBeDeletedBySession(adminSession), isTrue);
      expect(tIncident.canBeDeletedBySession(guardSession), isFalse);
      expect(tIncident.canBeDeletedBySession(null), isFalse);
    });

    test('getters isOpen, isResolved, isDeleted evaluate correctly', () {
      expect(tIncident.isOpen, isTrue);
      expect(tIncident.isResolved, isFalse);
      expect(tIncident.isDeleted, isFalse);

      final resolved = tIncident.copyWith(status: IncidentStatus.resolved);
      expect(resolved.isOpen, isFalse);
      expect(resolved.isResolved, isTrue);
      expect(resolved.isDeleted, isFalse);

      final deleted = tIncident.copyWith(deletedAt: DateTime.now());
      expect(deleted.isOpen, isFalse);
      expect(deleted.isResolved, isFalse);
      expect(deleted.isDeleted, isTrue);
    });
  });
}
