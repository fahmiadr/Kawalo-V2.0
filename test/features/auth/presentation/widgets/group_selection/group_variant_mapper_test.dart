import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/auth/presentation/widgets/group_selection/group_variant_mapper.dart';

void main() {
  group('roleToVariant', () {
    test('maps known categories case-insensitively', () {
      expect(roleToVariant('ADMIN'), AppTagVariant.primary);
      expect(roleToVariant('guard'), AppTagVariant.secondary);
      expect(roleToVariant('Staff'), AppTagVariant.tertiary);
    });

    test('falls back to neutral for USER, unknown and null', () {
      expect(roleToVariant('USER'), AppTagVariant.neutral);
      expect(roleToVariant('OTHER'), AppTagVariant.neutral);
      expect(roleToVariant(null), AppTagVariant.neutral);
    });
  });

  group('groupStatusToVariant', () {
    test('maps known statuses case-insensitively', () {
      expect(groupStatusToVariant('PAID'), AppTagVariant.primary);
      expect(groupStatusToVariant('client'), AppTagVariant.secondary);
      expect(groupStatusToVariant('Trial'), AppTagVariant.tertiary);
    });

    test('falls back to neutral for unknown and null', () {
      expect(groupStatusToVariant('FREE'), AppTagVariant.neutral);
      expect(groupStatusToVariant(null), AppTagVariant.neutral);
    });
  });
}
