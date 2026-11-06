import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/group/data/models/group_member_model.dart';

void main() {
  group('GroupMemberModel', () {
    test('fromJson should parse camelCase correctly without fallbacks', () {
      final json = {
        'email': 'member@kawalo.id',
        'name': 'Member Name',
        'profilePic': 'https://example.com/avatar.png',
      };

      final result = GroupMemberModel.fromJson(json);

      expect(result.email, 'member@kawalo.id');
      expect(result.name, 'Member Name');
      expect(result.profilePic, 'https://example.com/avatar.png');
    });

    test('fromJson should handle null optional fields', () {
      final json = {
        'email': 'member@kawalo.id',
      };

      final result = GroupMemberModel.fromJson(json);

      expect(result.email, 'member@kawalo.id');
      expect(result.name, isNull);
      expect(result.profilePic, isNull);
    });

    test('props equality works as expected', () {
      const modelA = GroupMemberModel(
        email: 'test@kawalo.id',
        name: 'Test',
      );
      const modelB = GroupMemberModel(
        email: 'test@kawalo.id',
        name: 'Test',
      );

      expect(modelA, equals(modelB));
    });
  });
}
