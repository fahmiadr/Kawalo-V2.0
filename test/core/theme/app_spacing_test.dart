import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';

void main() {
  group('AppSpacing M3 Expressive Semantic Scale', () {
    test('AppSpacing semantic tokens match M3EDimensions', () {
      expect(AppSpacing.xs, M3EDimensions.spaceXs); // 4dp
      expect(AppSpacing.sm, M3EDimensions.spaceSm); // 8dp
      expect(AppSpacing.md, M3EDimensions.spaceMd); // 12dp
      expect(AppSpacing.lg, M3EDimensions.spaceLg); // 16dp
      expect(AppSpacing.xl, M3EDimensions.spaceXl); // 24dp
      expect(AppSpacing.xxl, M3EDimensions.spaceXxl); // 32dp
    });

    test('AppSpacing.regularScale provides full 6-step scale', () {
      const scale = AppSpacing.regularScale;
      expect(scale.xs, 4);
      expect(scale.sm, 8);
      expect(scale.md, 12);
      expect(scale.lg, 16);
      expect(scale.xl, 24);
      expect(scale.xxl, 32);
    });
  });

  group('AppSpacing 4dp/8dp Grid Scalar Tokens', () {
    test('AppSpacing scalar values match expected dp values', () {
      expect(AppSpacing.space0, 0);
      expect(AppSpacing.space25, 2);
      expect(AppSpacing.space50, 4);
      expect(AppSpacing.space75, 6);
      expect(AppSpacing.space100, 8);
      expect(AppSpacing.space125, 10);
      expect(AppSpacing.space150, 12);
      expect(AppSpacing.space175, 14);
      expect(AppSpacing.space200, 16);
      expect(AppSpacing.space250, 20);
      expect(AppSpacing.space300, 24);
      expect(AppSpacing.space350, 28);
      expect(AppSpacing.space400, 32);
      expect(AppSpacing.space450, 36);
      expect(AppSpacing.space500, 40);
      expect(AppSpacing.space600, 48);
      expect(AppSpacing.space700, 56);
      expect(AppSpacing.space800, 64);
      expect(AppSpacing.space900, 72);
    });

    test('AppSpacing.customToken calculates proportional values', () {
      expect(AppSpacing.customToken(100), 8);
      expect(AppSpacing.customToken(200), 16);
      expect(AppSpacing.customToken(50), 4);
      expect(AppSpacing.customToken(150), 12);
    });
  });

  group('AppSpacing EdgeInsets Helpers', () {
    test('Padding all helpers have correct insets', () {
      expect(AppSpacing.paddingAllNone, EdgeInsets.zero);
      expect(AppSpacing.paddingAllXs, const EdgeInsets.all(4));
      expect(AppSpacing.paddingAllSm, const EdgeInsets.all(8));
      expect(AppSpacing.paddingAllMd, const EdgeInsets.all(12));
      expect(AppSpacing.paddingAllLg, const EdgeInsets.all(16));
      expect(AppSpacing.paddingAllXl, const EdgeInsets.all(24));
      expect(AppSpacing.paddingAllXxl, const EdgeInsets.all(32));
    });

    test('Padding symmetric helpers have correct insets', () {
      expect(
        AppSpacing.paddingHorizontalSm,
        const EdgeInsets.symmetric(horizontal: 8),
      );
      expect(
        AppSpacing.paddingHorizontalMd,
        const EdgeInsets.symmetric(horizontal: 12),
      );
      expect(
        AppSpacing.paddingHorizontalLg,
        const EdgeInsets.symmetric(horizontal: 16),
      );
      expect(
        AppSpacing.paddingHorizontalXl,
        const EdgeInsets.symmetric(horizontal: 24),
      );
      expect(
        AppSpacing.paddingVerticalSm,
        const EdgeInsets.symmetric(vertical: 8),
      );
      expect(
        AppSpacing.paddingVerticalMd,
        const EdgeInsets.symmetric(vertical: 12),
      );
      expect(
        AppSpacing.paddingVerticalLg,
        const EdgeInsets.symmetric(vertical: 16),
      );
      expect(
        AppSpacing.paddingVerticalXl,
        const EdgeInsets.symmetric(vertical: 24),
      );
    });
  });

  group('AppSpacing SizedBox Gap Helpers', () {
    test('Square gap dimensions match tokens', () {
      expect(AppSpacing.gapXs.width, 4);
      expect(AppSpacing.gapXs.height, 4);
      expect(AppSpacing.gapSm.width, 8);
      expect(AppSpacing.gapSm.height, 8);
      expect(AppSpacing.gapMd.width, 12);
      expect(AppSpacing.gapMd.height, 12);
      expect(AppSpacing.gapLg.width, 16);
      expect(AppSpacing.gapLg.height, 16);
      expect(AppSpacing.gapXl.width, 24);
      expect(AppSpacing.gapXl.height, 24);
      expect(AppSpacing.gapXxl.width, 32);
      expect(AppSpacing.gapXxl.height, 32);
    });

    test('Vertical gap dimensions match tokens', () {
      expect(AppSpacing.vGapXs.height, 4);
      expect(AppSpacing.vGapSm.height, 8);
      expect(AppSpacing.vGapMd.height, 12);
      expect(AppSpacing.vGapLg.height, 16);
      expect(AppSpacing.vGapXl.height, 24);
      expect(AppSpacing.vGapXxl.height, 32);
    });

    test('Horizontal gap dimensions match tokens', () {
      expect(AppSpacing.hGapXs.width, 4);
      expect(AppSpacing.hGapSm.width, 8);
      expect(AppSpacing.hGapMd.width, 12);
      expect(AppSpacing.hGapLg.width, 16);
      expect(AppSpacing.hGapXl.width, 24);
      expect(AppSpacing.hGapXxl.width, 32);
    });
  });
}
