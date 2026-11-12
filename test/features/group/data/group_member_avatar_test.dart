import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/group/data/mappers/group_member_mapper.dart';
import 'package:kawalo_mobile/features/group/data/models/group_member_model.dart';

void main() {
  GroupMemberModel parse(Map<String, dynamic> extra) =>
      GroupMemberModel.fromJson({'email': 'a@kawalo.id', ...extra});

  test('avatar_url is parsed and preferred over profilePic', () {
    final model = parse({
      'avatar_url': 'https://x.id/new.webp',
      'profilePic': 'https://x.id/old.webp',
    });

    expect(model.avatarUrl, 'https://x.id/new.webp');
    expect(
      GroupMemberMapper.toEntity(model).profilePic,
      'https://x.id/new.webp',
    );
  });

  test('profilePic still works without avatar_url', () {
    final entity = GroupMemberMapper.toEntity(
      parse({'profilePic': 'https://x.id/old.webp'}),
    );

    expect(entity.profilePic, 'https://x.id/old.webp');
  });

  test('a null avatar_url falls back to profilePic and then to null', () {
    expect(
      GroupMemberMapper.toEntity(
        parse({'avatar_url': null, 'profilePic': 'https://x.id/old.webp'}),
      ).profilePic,
      'https://x.id/old.webp',
    );
    expect(GroupMemberMapper.toEntity(parse({})).profilePic, isNull);
  });
}
