import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/auth/data/mappers/auth_mapper.dart';
import 'package:kawalo_mobile/features/auth/data/models/auth_session_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/auth_tokens_model.dart';
import 'package:kawalo_mobile/features/auth/data/models/user_model.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/auth_tokens_entity.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';

void main() {
  group('AuthMapper Tests', () {
    test('toTokensEntity normalizes tokens model to domain entity', () {
      const model = AuthTokensModel(
        accessToken: '  jwt_access_token  ',
        refreshToken: '  jwt_refresh_token  ',
        tokenType: ' Bearer ',
        expiresIn: 1800,
      );

      final entity = AuthMapper.toTokensEntity(model);
      expect(entity.accessToken, 'jwt_access_token');
      expect(entity.refreshToken, 'jwt_refresh_token');
      expect(entity.tokenType, 'Bearer');
      expect(entity.expiresIn, 1800);
    });

    test('toTokensModel converts entity to pure DTO model', () {
      const entity = AuthTokensEntity(
        accessToken: 'token_abc',
        refreshToken: 'refresh_xyz',
        tokenType: 'Bearer',
        expiresIn: 900,
      );

      final model = AuthMapper.toTokensModel(entity);
      expect(model.accessToken, 'token_abc');
      expect(model.refreshToken, 'refresh_xyz');
      expect(model.tokenType, 'Bearer');
      expect(model.expiresIn, 900);
    });

    test('toUserGroupEntity normalizes category role and filters features', () {
      const groupModel = UserGroupModel(
        groupUid: ' grp_1 ',
        groupName: ' Group Satu ',
        category: ' guard ',
        allowAdmin: false,
        allowPatrol: false,
        allowMonPatrol: false,
        features: ['PATROL', '  ', 'N/A'],
      );

      final groupEntity = AuthMapper.toUserGroupEntity(groupModel);
      expect(groupEntity.groupUid, 'grp_1');
      expect(groupEntity.groupName, 'Group Satu');
      expect(groupEntity.category, 'GUARD');
      expect(groupEntity.features, ['PATROL']);
    });

    test(
      'toUserEntity normalizes email to lowercase and role to uppercase',
      () {
        const userModel = UserModel(
          id: ' 101 ',
          email: ' USER.PERSONIL@KAWALO.ID ',
          name: ' Budi Santoso ',
          groups: [],
          activeGroup: UserGroupModel(
            groupUid: 'grp_001',
            category: 'guard',
            allowAdmin: false,
            allowPatrol: false,
            allowMonPatrol: false,
            features: [],
          ),
        );

        final userEntity = AuthMapper.toUserEntity(userModel);
        expect(userEntity.id, '101');
        expect(userEntity.email, 'user.personil@kawalo.id');
        expect(userEntity.name, 'Budi Santoso');
        expect(userEntity.activeGroup?.category, 'GUARD');
      },
    );

    test('toUserEntity maps activeGroup with cleaned category', () {
      const userModel = UserModel(
        id: '102',
        email: 'personil@kawalo.id',
        name: 'Siti Aminah',
        groups: [],
        activeGroup: UserGroupModel(
          groupUid: 'grp_002',
          category: 'admin',
          allowAdmin: false,
          allowPatrol: false,
          allowMonPatrol: false,
          features: [],
        ),
      );

      final userEntity = AuthMapper.toUserEntity(userModel);
      expect(userEntity.activeGroup?.category, 'ADMIN');
    });

    test('toUserModel converts UserEntity to pure DTO model', () {
      const userEntity = UserEntity(
        id: '103',
        email: 'personil@kawalo.id',
        name: 'Personil 3',
        groups: [],
      );

      final model = AuthMapper.toUserModel(userEntity);
      expect(model.id, '103');
      expect(model.email, 'personil@kawalo.id');
      expect(model.name, 'Personil 3');
      expect(model.groups, isEmpty);
    });

    test('toSessionEntity sanitizes and normalizes session model', () {
      const model = AuthSessionModel(
        userId: ' usr_99 ',
        email: ' PERSONIL@KAWALO.ID ',
        name: ' Joko Widodo ',
        role: ' guard ',
        groupUid: ' grp_pos1 ',
        allowAdmin: false,
        allowPatrol: true,
        allowMonPatrol: false,
      );

      final entity = AuthMapper.toSessionEntity(model);
      expect(entity.userId, 'usr_99');
      expect(entity.email, 'personil@kawalo.id');
      expect(entity.name, 'Joko Widodo');
      expect(entity.role, 'GUARD');
      expect(entity.groupUid, 'grp_pos1');
      expect(entity.allowAdmin, isFalse);
      expect(entity.allowPatrol, isTrue);
      expect(entity.allowMonPatrol, isFalse);
    });

    test('toSessionModel converts entity back to model faithfully', () {
      const entity = AuthSessionEntity(
        userId: 'usr_99',
        email: 'personil@kawalo.id',
        name: 'Joko Widodo',
        role: 'GUARD',
        groupUid: 'grp_pos1',
        allowAdmin: false,
        allowPatrol: true,
        allowMonPatrol: false,
      );

      final model = AuthMapper.toSessionModel(entity);
      expect(model.userId, 'usr_99');
      expect(model.email, 'personil@kawalo.id');
      expect(model.name, 'Joko Widodo');
      expect(model.role, 'GUARD');
      expect(model.groupUid, 'grp_pos1');
      expect(model.allowAdmin, isFalse);
      expect(model.allowPatrol, isTrue);
      expect(model.allowMonPatrol, isFalse);
    });

    test('Extension helpers work reciprocally', () {
      const model = AuthTokensModel(
        accessToken: 'acc',
        refreshToken: 'ref',
        tokenType: 'Bearer',
        expiresIn: 900,
      );
      final entity = model.toEntity();
      expect(entity.toModel().accessToken, 'acc');

      const sessionModel = AuthSessionModel(
        userId: 'u1',
        email: 'u@k.com',
        name: 'User 1',
        allowAdmin: true,
        allowPatrol: false,
        allowMonPatrol: false,
      );
      final sessionEntity = sessionModel.toEntity();
      expect(sessionEntity.toModel().userId, 'u1');
    });
  });
}
