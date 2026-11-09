import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/auth/data/models/auth_session_model.dart';

void main() {
  group('AuthSessionModel', () {
    const tSession = AuthSessionModel(
      userId: 'usr_001',
      email: 'personil@kawalo.id',
      name: 'Budi Santoso',
      role: 'GUARD',
      groupUid: 'grp_pos1',
      allowAdmin: false,
      allowPatrol: true,
      allowMonPatrol: false,
    );

    test('fromJwtPayload parses standard token payload correctly', () {
      final payload = <String, dynamic>{
        'sub': 'usr_001',
        'email': 'personil@kawalo.id',
        'name': 'Budi Santoso',
        'role': 'GUARD',
        'group_uid': 'grp_pos1',
        'allow_admin': false,
        'allow_patrol': true,
        'allow_mon_patrol': false,
      };

      final model = AuthSessionModel.fromJwtPayload(payload);

      expect(model.userId, 'usr_001');
      expect(model.email, 'personil@kawalo.id');
      expect(model.name, 'Budi Santoso');
      expect(model.role, 'GUARD');
      expect(model.groupUid, 'grp_pos1');
      expect(model.allowAdmin, isFalse);
      expect(model.allowPatrol, isTrue);
      expect(model.allowMonPatrol, isFalse);
    });

    test('fromJwtPayload handles nullable optional fields gracefully', () {
      final payload = <String, dynamic>{
        'sub': 'usr_002',
        'email': 'admin@kawalo.id',
        'name': 'Siti Admin',
        'allow_admin': false,
        'allow_patrol': false,
        'allow_mon_patrol': false,
      };

      final model = AuthSessionModel.fromJwtPayload(payload);

      expect(model.userId, 'usr_002');
      expect(model.email, 'admin@kawalo.id');
      expect(model.name, 'Siti Admin');
      expect(model.role, isNull);
      expect(model.groupUid, isNull);
      expect(model.allowAdmin, isFalse);
      expect(model.allowPatrol, isFalse);
      expect(model.allowMonPatrol, isFalse);
    });

    test('fromJwtPayload defaults missing allow_* flags to false', () {
      final model = AuthSessionModel.fromJwtPayload(const <String, dynamic>{
        'sub': 'usr_003',
        'email': 'guard@kawalo.id',
        'name': 'Andi',
      });

      expect(model.allowAdmin, isFalse);
      expect(model.allowPatrol, isFalse);
      expect(model.allowMonPatrol, isFalse);
    });

    test('fromJwtPayload does not treat non-bool flags as granted', () {
      final model = AuthSessionModel.fromJwtPayload(const <String, dynamic>{
        'sub': 'usr_003',
        'email': 'guard@kawalo.id',
        'name': 'Andi',
        'allow_admin': 'true',
        'allow_patrol': 1,
        'allow_mon_patrol': null,
      });

      expect(model.allowAdmin, isFalse);
      expect(model.allowPatrol, isFalse);
      expect(model.allowMonPatrol, isFalse);
    });

    for (final claim in ['sub', 'email', 'name']) {
      test(
        'fromJwtPayload throws FormatException when "$claim" is missing',
        () {
          final payload = <String, dynamic>{
            'sub': 'usr_001',
            'email': 'personil@kawalo.id',
            'name': 'Budi Santoso',
          }..remove(claim);

          expect(
            () => AuthSessionModel.fromJwtPayload(payload),
            throwsA(
              isA<FormatException>().having(
                (e) => e.message,
                'message',
                contains(claim),
              ),
            ),
          );
        },
      );
    }

    test(
      'fromJwtPayload throws FormatException when a claim has wrong type',
      () {
        expect(
          () => AuthSessionModel.fromJwtPayload(const <String, dynamic>{
            'sub': 42,
            'email': 'personil@kawalo.id',
            'name': 'Budi Santoso',
          }),
          throwsFormatException,
        );
      },
    );

    test('fromJson defaults missing allow_* flags to false', () {
      final model = AuthSessionModel.fromJson(const <String, dynamic>{
        'user_id': 'usr_001',
        'email': 'personil@kawalo.id',
        'name': 'Budi Santoso',
      });

      expect(model.allowAdmin, isFalse);
      expect(model.allowPatrol, isFalse);
      expect(model.allowMonPatrol, isFalse);
      expect(model.role, isNull);
      expect(model.groupUid, isNull);
    });

    test('fromJson throws an Exception (not TypeError) on missing user_id', () {
      expect(
        () => AuthSessionModel.fromJson(const <String, dynamic>{
          'email': 'personil@kawalo.id',
          'name': 'Budi Santoso',
        }),
        throwsA(isA<Exception>()),
      );
    });

    test('fromJson and toJson perform lossless roundtrip serialization', () {
      final json = tSession.toJson();
      final fromJsonModel = AuthSessionModel.fromJson(json);

      expect(fromJsonModel, equals(tSession));
      expect(json['user_id'], 'usr_001');
      expect(json['email'], 'personil@kawalo.id');
      expect(json['name'], 'Budi Santoso');
      expect(json['role'], 'GUARD');
      expect(json['group_uid'], 'grp_pos1');
      expect(json['allow_admin'], isFalse);
      expect(json['allow_patrol'], isTrue);
      expect(json['allow_mon_patrol'], isFalse);
    });

    test('props equality works across identical instances', () {
      const duplicate = AuthSessionModel(
        userId: 'usr_001',
        email: 'personil@kawalo.id',
        name: 'Budi Santoso',
        role: 'GUARD',
        groupUid: 'grp_pos1',
        allowAdmin: false,
        allowPatrol: true,
        allowMonPatrol: false,
      );

      expect(tSession, equals(duplicate));
    });
  });
}
