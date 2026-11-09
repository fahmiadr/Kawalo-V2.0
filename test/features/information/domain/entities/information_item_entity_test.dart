import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';

void main() {
  group('InformationItemEntity Tests', () {
    const tAuthorEmail = 'guard1@kawalo.id';
    const tFeed = InformationItemEntity(
      id: '101',
      photos: [],
      title: 'Laporan Patroli',
      userEmail: tAuthorEmail,
      glat: -6.2088,
      glong: 106.8456,
    );

    test('supports value equality with glat and glong', () {
      const other = InformationItemEntity(
        id: '101',
        photos: [],
        title: 'Laporan Patroli',
        userEmail: tAuthorEmail,
        glat: -6.2088,
        glong: 106.8456,
      );

      expect(tFeed, equals(other));
      expect(tFeed.glat, -6.2088);
      expect(tFeed.glong, 106.8456);
    });

    test('canBeDeletedBySession returns false for null session', () {
      expect(tFeed.canBeDeletedBySession(null), isFalse);
    });

    test('canBeDeletedBySession returns false when role is null or empty', () {
      const nullRoleSession = AuthSessionEntity(
        userId: '1',
        email: tAuthorEmail,
        name: 'No Role',
        allowAdmin: false,
        allowPatrol: false,
        allowMonPatrol: false,
      );
      expect(tFeed.canBeDeletedBySession(nullRoleSession), isFalse);

      const emptyRoleSession = AuthSessionEntity(
        userId: '1',
        email: tAuthorEmail,
        name: 'Empty Role',
        role: '',
        allowAdmin: false,
        allowPatrol: false,
        allowMonPatrol: false,
      );
      expect(tFeed.canBeDeletedBySession(emptyRoleSession), isFalse);
    });

    test('canBeDeletedBySession returns true for ADMIN regardless '
        'of email', () {
      const adminSession = AuthSessionEntity(
        userId: '1',
        email: 'other@kawalo.id',
        name: 'Admin',
        role: 'ADMIN',
        allowAdmin: true,
        allowPatrol: false,
        allowMonPatrol: false,
      );
      expect(tFeed.canBeDeletedBySession(adminSession), isTrue);
    });

    test('canBeDeletedBySession returns true for GUARD only if '
        'email matches author', () {
      // Matching email
      const matchGuardSession = AuthSessionEntity(
        userId: '2',
        email: tAuthorEmail,
        name: 'Guard',
        role: 'GUARD',
        allowAdmin: false,
        allowPatrol: true,
        allowMonPatrol: false,
      );
      expect(tFeed.canBeDeletedBySession(matchGuardSession), isTrue);

      // Different email
      const otherGuardSession = AuthSessionEntity(
        userId: '3',
        email: 'guard2@kawalo.id',
        name: 'Other Guard',
        role: 'GUARD',
        allowAdmin: false,
        allowPatrol: true,
        allowMonPatrol: false,
      );
      expect(tFeed.canBeDeletedBySession(otherGuardSession), isFalse);

      // Case-insensitive and trimmed email matching
      const caseGuardSession = AuthSessionEntity(
        userId: '2',
        email: ' GUARD1@KAWALO.ID ',
        name: 'Guard Upper',
        role: 'guard',
        allowAdmin: false,
        allowPatrol: true,
        allowMonPatrol: false,
      );
      expect(tFeed.canBeDeletedBySession(caseGuardSession), isTrue);
    });

    test('canBeDeletedBySession returns true when allowAdmin is true', () {
      const allowAdminSession = AuthSessionEntity(
        userId: '10',
        email: 'admin_flag@kawalo.id',
        name: 'Admin Flag',
        allowAdmin: true,
        allowPatrol: false,
        allowMonPatrol: false,
      );
      expect(tFeed.canBeDeletedBySession(allowAdminSession), isTrue);
    });

    test('canBeDeletedBySession returns false for other roles '
        '(e.g. CITIZEN, GUEST)', () {
      const citizenSession = AuthSessionEntity(
        userId: '4',
        email: tAuthorEmail,
        name: 'Citizen',
        role: 'CITIZEN',
        allowAdmin: false,
        allowPatrol: false,
        allowMonPatrol: false,
      );
      expect(tFeed.canBeDeletedBySession(citizenSession), isFalse);

      const guestSession = AuthSessionEntity(
        userId: '5',
        email: tAuthorEmail,
        name: 'Guest',
        role: 'GUEST',
        allowAdmin: false,
        allowPatrol: false,
        allowMonPatrol: false,
      );
      expect(tFeed.canBeDeletedBySession(guestSession), isFalse);
    });

    test('canBeUpdatedBySession returns false for null session', () {
      expect(tFeed.canBeUpdatedBySession(null), isFalse);
    });

    test(
      'canBeUpdatedBySession returns true for ADMIN regardless of email',
      () {
        const adminSession = AuthSessionEntity(
          userId: '1',
          email: 'other@kawalo.id',
          name: 'Admin',
          role: 'ADMIN',
          allowAdmin: true,
          allowPatrol: false,
          allowMonPatrol: false,
        );
        expect(tFeed.canBeUpdatedBySession(adminSession), isTrue);
      },
    );

    test(
      'canBeUpdatedBySession returns true for GUARD only if email matches',
      () {
        const matchGuardSession = AuthSessionEntity(
          userId: '2',
          email: tAuthorEmail,
          name: 'Guard',
          role: 'GUARD',
          allowAdmin: false,
          allowPatrol: true,
          allowMonPatrol: false,
        );
        expect(tFeed.canBeUpdatedBySession(matchGuardSession), isTrue);

        const otherGuardSession = AuthSessionEntity(
          userId: '3',
          email: 'guard2@kawalo.id',
          name: 'Other Guard',
          role: 'GUARD',
          allowAdmin: false,
          allowPatrol: true,
          allowMonPatrol: false,
        );
        expect(tFeed.canBeUpdatedBySession(otherGuardSession), isFalse);
      },
    );

    test(
      'canBeUpdatedBySession returns false for other roles or empty role',
      () {
        const emptyRoleSession = AuthSessionEntity(
          userId: '1',
          email: tAuthorEmail,
          name: 'Empty Role',
          role: '',
          allowAdmin: false,
          allowPatrol: false,
          allowMonPatrol: false,
        );
        expect(tFeed.canBeUpdatedBySession(emptyRoleSession), isFalse);

        const citizenSession = AuthSessionEntity(
          userId: '4',
          email: tAuthorEmail,
          name: 'Citizen',
          role: 'CITIZEN',
          allowAdmin: false,
          allowPatrol: false,
          allowMonPatrol: false,
        );
        expect(tFeed.canBeUpdatedBySession(citizenSession), isFalse);
      },
    );

    test('canBeCreatedBySession returns true for ADMIN and GUARD', () {
      const adminSession = AuthSessionEntity(
        userId: '1',
        email: 'admin@kawalo.id',
        name: 'Admin',
        role: 'ADMIN',
        allowAdmin: true,
        allowPatrol: true,
        allowMonPatrol: true,
      );
      expect(InformationItemEntity.canBeCreatedBySession(adminSession), isTrue);

      const guardSession = AuthSessionEntity(
        userId: '2',
        email: 'guard@kawalo.id',
        name: 'Guard',
        role: 'GUARD',
        allowAdmin: false,
        allowPatrol: true,
        allowMonPatrol: false,
      );
      expect(InformationItemEntity.canBeCreatedBySession(guardSession), isTrue);
    });

    test(
      'canBeCreatedBySession returns false for null, empty, or other roles',
      () {
        expect(InformationItemEntity.canBeCreatedBySession(null), isFalse);

        const emptyRoleSession = AuthSessionEntity(
          userId: '1',
          email: 'user@kawalo.id',
          name: 'Empty Role',
          role: '',
          allowAdmin: false,
          allowPatrol: false,
          allowMonPatrol: false,
        );
        expect(
          InformationItemEntity.canBeCreatedBySession(emptyRoleSession),
          isFalse,
        );

        const citizenSession = AuthSessionEntity(
          userId: '4',
          email: 'citizen@kawalo.id',
          name: 'Citizen',
          role: 'CITIZEN',
          allowAdmin: false,
          allowPatrol: false,
          allowMonPatrol: false,
        );
        expect(
          InformationItemEntity.canBeCreatedBySession(citizenSession),
          isFalse,
        );
      },
    );
  });
}
