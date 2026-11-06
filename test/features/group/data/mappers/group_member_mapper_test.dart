import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/group/data/mappers/group_member_mapper.dart';
import 'package:kawalo_mobile/features/group/data/models/group_member_model.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';

void main() {
  group('GroupMemberMapper', () {
    const tModel = GroupMemberModel(
      email: 'user@kawalo.id',
      name: 'User Test',
      profilePic: 'https://example.com/pic.jpg',
    );

    const tEntity = GroupMemberEntity(
      email: 'user@kawalo.id',
      name: 'User Test',
      profilePic: 'https://example.com/pic.jpg',
    );

    test('toEntity should map model to entity and lowercase email', () {
      final entity = GroupMemberMapper.toEntity(tModel);
      expect(entity, equals(tEntity));
    });

    test(
      'toEntity should sanitize empty, null, N/A, and dash values to null',
      () {
        const dirtyModel = GroupMemberModel(
          email: 'Member@Kawalo.Id',
          name: '  null  ',
          profilePic: '  -  ',
        );

        final entity = GroupMemberMapper.toEntity(dirtyModel);

        expect(entity.email, 'member@kawalo.id');
        expect(entity.name, isNull);
        expect(entity.profilePic, isNull);

        const dirtyModel2 = GroupMemberModel(
          email: '  ',
          name: 'N/A',
          profilePic: '   ',
        );

        final entity2 = GroupMemberMapper.toEntity(dirtyModel2);
        expect(entity2.name, isNull);
        expect(entity2.profilePic, isNull);
      },
    );

    test('toEntityList should map list to fixed-length list (growable: false)',
        () {
      final entities = GroupMemberMapper.toEntityList([tModel]);

      expect(entities, equals([tEntity]));
      expect(
        () => entities.add(tEntity),
        throwsUnsupportedError,
      );
    });
  });
}
