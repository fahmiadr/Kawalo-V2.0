import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';

void main() {
  group('GuestItemEntity Authorization Tests', () {
    const tAuthorEmail = 'guard1@kawalo.id';
    const tGuest = GuestItemEntity(
      id: '101',
      guestName: 'Budi Santoso',
      guestCreatorEmail: tAuthorEmail,
    );

    test('canBeDeletedBySession returns false for null session', () {
      expect(tGuest.canBeDeletedBySession(null), isFalse);
    });

    test(
      'canBeDeletedBySession returns false when role is null or empty',
      () {
        const nullRoleSession = AuthSessionEntity(
          userId: '1',
          email: tAuthorEmail,
          name: 'No Role',
          allowAdmin: false,
          allowPatrol: false,
          allowMonPatrol: false,
        );
        expect(tGuest.canBeDeletedBySession(nullRoleSession), isFalse);

        const emptyRoleSession = AuthSessionEntity(
          userId: '1',
          email: tAuthorEmail,
          name: 'Empty Role',
          role: '',
          allowAdmin: false,
          allowPatrol: false,
          allowMonPatrol: false,
        );
        expect(tGuest.canBeDeletedBySession(emptyRoleSession), isFalse);
      },
    );

    test('canBeDeletedBySession returns true for ADMIN regardless of email',
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
      expect(tGuest.canBeDeletedBySession(adminSession), isTrue);
    });

    test(
      'canBeDeletedBySession returns true for GUARD only if email matches '
      'guestCreatorEmail',
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
        expect(tGuest.canBeDeletedBySession(matchGuardSession), isTrue);

        const otherGuardSession = AuthSessionEntity(
          userId: '3',
          email: 'guard2@kawalo.id',
          name: 'Other Guard',
          role: 'GUARD',
          allowAdmin: false,
          allowPatrol: true,
          allowMonPatrol: false,
        );
        expect(tGuest.canBeDeletedBySession(otherGuardSession), isFalse);

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
        expect(tGuest.canBeDeletedBySession(caseGuardSession), isTrue);
      },
    );

    test('canBeDeletedBySession returns true when allowAdmin is true', () {
      const allowAdminSession = AuthSessionEntity(
        userId: '10',
        email: 'admin_flag@kawalo.id',
        name: 'Admin Flag',
        allowAdmin: true,
        allowPatrol: false,
        allowMonPatrol: false,
      );
      expect(tGuest.canBeDeletedBySession(allowAdminSession), isTrue);
    });

    test(
      'canBeDeletedBySession returns false for other roles '
      '(e.g. CITIZEN, GUEST)',
      () {
        const citizenSession = AuthSessionEntity(
          userId: '4',
          email: tAuthorEmail,
          name: 'Citizen',
          role: 'CITIZEN',
          allowAdmin: false,
          allowPatrol: false,
          allowMonPatrol: false,
        );
        expect(tGuest.canBeDeletedBySession(citizenSession), isFalse);

        const guestSession = AuthSessionEntity(
          userId: '5',
          email: tAuthorEmail,
          name: 'Guest',
          role: 'GUEST',
          allowAdmin: false,
          allowPatrol: false,
          allowMonPatrol: false,
        );
        expect(tGuest.canBeDeletedBySession(guestSession), isFalse);
      },
    );

    test('canBeCreatedBySession returns true for ADMIN and GUARD', () {
      expect(GuestItemEntity.canBeCreatedBySession(null), isFalse);

      const adminSession = AuthSessionEntity(
        userId: '1',
        email: 'admin@kawalo.id',
        name: 'Admin',
        role: 'ADMIN',
        allowAdmin: true,
        allowPatrol: true,
        allowMonPatrol: true,
      );
      expect(GuestItemEntity.canBeCreatedBySession(adminSession), isTrue);

      const guardSession = AuthSessionEntity(
        userId: '2',
        email: 'guard@kawalo.id',
        name: 'Guard',
        role: 'GUARD',
        allowAdmin: false,
        allowPatrol: true,
        allowMonPatrol: false,
      );
      expect(GuestItemEntity.canBeCreatedBySession(guardSession), isTrue);

      const citizenSession = AuthSessionEntity(
        userId: '3',
        email: 'citizen@kawalo.id',
        name: 'Citizen',
        role: 'CITIZEN',
        allowAdmin: false,
        allowPatrol: false,
        allowMonPatrol: false,
      );
      expect(GuestItemEntity.canBeCreatedBySession(citizenSession), isFalse);
    });

    test('canBeUpdatedBySession returns false for null session', () {
      expect(tGuest.canBeUpdatedBySession(null), isFalse);
    });

    test(
      'canBeUpdatedBySession returns false when role is null or empty',
      () {
        const nullRoleSession = AuthSessionEntity(
          userId: '1',
          email: tAuthorEmail,
          name: 'No Role',
          allowAdmin: false,
          allowPatrol: false,
          allowMonPatrol: false,
        );
        expect(tGuest.canBeUpdatedBySession(nullRoleSession), isFalse);

        const emptyRoleSession = AuthSessionEntity(
          userId: '1',
          email: tAuthorEmail,
          name: 'Empty Role',
          role: '',
          allowAdmin: false,
          allowPatrol: false,
          allowMonPatrol: false,
        );
        expect(tGuest.canBeUpdatedBySession(emptyRoleSession), isFalse);
      },
    );

    test('canBeUpdatedBySession returns true for ADMIN regardless of email',
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
      expect(tGuest.canBeUpdatedBySession(adminSession), isTrue);
    });

    test(
      'canBeUpdatedBySession returns true for GUARD only if email matches '
      'guestCreatorEmail',
      () {
        const matchingGuardSession = AuthSessionEntity(
          userId: '2',
          email: tAuthorEmail,
          name: 'Matching Guard',
          role: 'GUARD',
          allowAdmin: false,
          allowPatrol: true,
          allowMonPatrol: false,
        );
        expect(tGuest.canBeUpdatedBySession(matchingGuardSession), isTrue);

        const otherGuardSession = AuthSessionEntity(
          userId: '3',
          email: 'other_guard@kawalo.id',
          name: 'Other Guard',
          role: 'GUARD',
          allowAdmin: false,
          allowPatrol: true,
          allowMonPatrol: false,
        );
        expect(tGuest.canBeUpdatedBySession(otherGuardSession), isFalse);
      },
    );

    test(
      'canBeUpdatedBySession returns false for GUARD when '
      'guestCreatorEmail is null',
      () {
        const guestWithoutAuthor = GuestItemEntity(id: '102');
        const guardSession = AuthSessionEntity(
          userId: '2',
          email: tAuthorEmail,
          name: 'Guard',
          role: 'GUARD',
          allowAdmin: false,
          allowPatrol: true,
          allowMonPatrol: false,
        );
        expect(
          guestWithoutAuthor.canBeUpdatedBySession(guardSession),
          isFalse,
        );
      },
    );

    test(
        'canBeUpdatedBySession returns false for non-ADMIN and non-GUARD roles',
        () {
      const citizenSession = AuthSessionEntity(
        userId: '4',
        email: tAuthorEmail,
        name: 'Citizen',
        role: 'CITIZEN',
        allowAdmin: false,
        allowPatrol: false,
        allowMonPatrol: false,
      );
      expect(tGuest.canBeUpdatedBySession(citizenSession), isFalse);
    });

    test('isExited evaluates correctly based on guestOutDt', () {
      const activeGuest = GuestItemEntity(id: '1');
      expect(activeGuest.isExited, isFalse);

      const emptyOutGuest = GuestItemEntity(id: '2', guestOutDt: '');
      expect(emptyOutGuest.isExited, isFalse);

      const dashOutGuest = GuestItemEntity(id: '3', guestOutDt: '-');
      expect(dashOutGuest.isExited, isFalse);

      const exitedGuest = GuestItemEntity(
        id: '4',
        guestOutDt: '2026-11-02T10:00:00.000Z',
      );
      expect(exitedGuest.isExited, isTrue);
    });

    test('canBeCheckedOutBySession authorization rules', () {
      const activeGuest = GuestItemEntity(
        id: '101',
        guestName: 'Budi Santoso',
        guestCreatorEmail: 'creator@kawalo.id',
      );
      const exitedGuest = GuestItemEntity(
        id: '102',
        guestOutDt: '2026-11-02T10:00:00.000Z',
      );

      // 1. Null session returns false
      expect(activeGuest.canBeCheckedOutBySession(null), isFalse);

      // 2. Already exited guest always returns false
      const adminSession = AuthSessionEntity(
        userId: '1',
        email: 'admin@kawalo.id',
        name: 'Admin',
        role: 'ADMIN',
        allowAdmin: true,
        allowPatrol: false,
        allowMonPatrol: false,
      );
      expect(exitedGuest.canBeCheckedOutBySession(adminSession), isFalse);

      // 3. Admin can checkout any active guest
      expect(activeGuest.canBeCheckedOutBySession(adminSession), isTrue);

      // 4. Guard can checkout active guest (even if not the creator)
      const guardSession = AuthSessionEntity(
        userId: '2',
        email: 'other_guard@kawalo.id',
        name: 'Guard',
        role: 'GUARD',
        allowAdmin: false,
        allowPatrol: true,
        allowMonPatrol: false,
      );
      expect(activeGuest.canBeCheckedOutBySession(guardSession), isTrue);

      // 5. Resident / non-guard/admin cannot checkout
      const residentSession = AuthSessionEntity(
        userId: '3',
        email: 'resident@kawalo.id',
        name: 'Resident',
        role: 'RESIDENT',
        allowAdmin: false,
        allowPatrol: false,
        allowMonPatrol: false,
      );
      expect(activeGuest.canBeCheckedOutBySession(residentSession), isFalse);
    });
  });
}
