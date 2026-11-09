import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';

void main() {
  group('AppRadius 10 Official M3 Corner Values', () {
    test('Corner scalar values match M3 specifications', () {
      expect(AppRadius.none, 0);
      expect(AppRadius.extraSmall, 4);
      expect(AppRadius.xs, 4);
      expect(AppRadius.small, 8);
      expect(AppRadius.sm, 8);
      expect(AppRadius.medium, 12);
      expect(AppRadius.md, 12);
      expect(AppRadius.large, 16);
      expect(AppRadius.lg, 16);
      expect(AppRadius.largeIncreased, 20);
      expect(AppRadius.lgIncreased, 20);
      expect(AppRadius.extraLarge, 28);
      expect(AppRadius.xl, 28);
      expect(AppRadius.extraLargeIncreased, 32);
      expect(AppRadius.xlIncreased, 32);
      expect(AppRadius.extraExtraLarge, 48);
      expect(AppRadius.xxl, 48);
      expect(AppRadius.full, 9999);
    });

    test('AppRadius.values list contains exactly 10 ordered tokens', () {
      expect(AppRadius.values.length, 10);
      expect(AppRadius.values, [0, 4, 8, 12, 16, 20, 28, 32, 48, 9999]);
    });
  });

  group('AppRadius Circular Radius & BorderRadius Objects', () {
    test('Radius objects have correct dimensions', () {
      expect(AppRadius.radiusNone, Radius.zero);
      expect(AppRadius.radiusExtraSmall, const Radius.circular(4));
      expect(AppRadius.radiusSmall, const Radius.circular(8));
      expect(AppRadius.radiusMedium, const Radius.circular(12));
      expect(AppRadius.radiusLarge, const Radius.circular(16));
      expect(AppRadius.radiusLargeIncreased, const Radius.circular(20));
      expect(AppRadius.radiusExtraLarge, const Radius.circular(28));
      expect(AppRadius.radiusExtraLargeIncreased, const Radius.circular(32));
      expect(AppRadius.radiusExtraExtraLarge, const Radius.circular(48));
      expect(AppRadius.radiusFull, const Radius.circular(9999));
    });

    test('Symmetric BorderRadius objects match uniform Radius.all tokens', () {
      expect(AppRadius.borderNone, BorderRadius.zero);
      expect(
        AppRadius.borderExtraSmall,
        const BorderRadius.all(Radius.circular(4)),
      );
      expect(AppRadius.borderSmall, const BorderRadius.all(Radius.circular(8)));
      expect(
        AppRadius.borderMedium,
        const BorderRadius.all(Radius.circular(12)),
      );
      expect(
        AppRadius.borderLarge,
        const BorderRadius.all(Radius.circular(16)),
      );
      expect(
        AppRadius.borderLargeIncreased,
        const BorderRadius.all(Radius.circular(20)),
      );
      expect(
        AppRadius.borderExtraLarge,
        const BorderRadius.all(Radius.circular(28)),
      );
      expect(
        AppRadius.borderExtraLargeIncreased,
        const BorderRadius.all(Radius.circular(32)),
      );
      expect(
        AppRadius.borderExtraExtraLarge,
        const BorderRadius.all(Radius.circular(48)),
      );
      expect(
        AppRadius.borderFull,
        const BorderRadius.all(Radius.circular(9999)),
      );
    });

    test('Directional BorderRadius objects round only intended sides', () {
      expect(
        AppRadius.borderExtraSmallTop,
        const BorderRadius.vertical(top: Radius.circular(4)),
      );
      expect(
        AppRadius.borderLargeTop,
        const BorderRadius.vertical(top: Radius.circular(16)),
      );
      expect(
        AppRadius.borderExtraLargeTop,
        const BorderRadius.vertical(top: Radius.circular(28)),
      );
      expect(
        AppRadius.borderLargeStart,
        const BorderRadius.horizontal(left: Radius.circular(16)),
      );
      expect(
        AppRadius.borderLargeEnd,
        const BorderRadius.horizontal(right: Radius.circular(16)),
      );
    });
  });

  group('AppRadius Optical Roundness & Concentric Corner Helpers', () {
    test('inner formula calculates correct nested radius', () {
      // Outer 28dp (xl) with 12dp padding -> 16dp (lg)
      expect(AppRadius.inner(28, 12), 16);

      // Outer 48dp (xxl) with 16dp padding -> 32dp (xlIncreased)
      expect(AppRadius.inner(48, 16), 32);

      // Padding larger than outer radius clamps to 0
      expect(AppRadius.inner(8, 16), 0);
    });

    test('snapToTokenValue snaps intermediate values to closest M3 token', () {
      expect(AppRadius.snapToTokenValue(5), 4); // Closest to 4
      expect(AppRadius.snapToTokenValue(7), 8); // Closest to 8
      expect(AppRadius.snapToTokenValue(15), 16); // Closest to 16
      expect(AppRadius.snapToTokenValue(25), 28); // Closest to 28
    });

    test('inner supports snapToToken parameter', () {
      // Outer 16dp with 5dp padding -> exact 11dp, snapped -> 12dp (medium)
      expect(AppRadius.inner(16, 5, snapToToken: true), 12);
      expect(AppRadius.inner(16, 5), 11);
    });

    test(
      'innerBorder returns concentric BorderRadius and supports snapToToken',
      () {
        final border = AppRadius.innerBorder(28, 12);
        expect(border, const BorderRadius.all(Radius.circular(16)));

        final snappedBorder = AppRadius.innerBorder(16, 5, snapToToken: true);
        expect(snappedBorder, const BorderRadius.all(Radius.circular(12)));
      },
    );
  });
}
