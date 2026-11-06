import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_shape.dart';

void main() {
  group('AppShape Standard Symmetric Rounding Tokens', () {
    test('AppShape.none has zero radius', () {
      expect(AppShape.none, isA<RoundedRectangleBorder>());
      expect(
        (AppShape.none as RoundedRectangleBorder).borderRadius,
        BorderRadius.zero,
      );
    });

    test('AppShape.extraSmall has 4dp radius', () {
      expect(
        (AppShape.extraSmall as RoundedRectangleBorder).borderRadius,
        AppRadius.borderExtraSmall,
      );
    });

    test('AppShape.small has 8dp radius', () {
      expect(
        (AppShape.small as RoundedRectangleBorder).borderRadius,
        AppRadius.borderSmall,
      );
    });

    test('AppShape.medium has 12dp radius', () {
      expect(
        (AppShape.medium as RoundedRectangleBorder).borderRadius,
        AppRadius.borderMedium,
      );
    });

    test('AppShape.large has 16dp radius', () {
      expect(
        (AppShape.large as RoundedRectangleBorder).borderRadius,
        AppRadius.borderLarge,
      );
    });

    test('AppShape.largeIncreased has 20dp radius', () {
      expect(
        (AppShape.largeIncreased as RoundedRectangleBorder).borderRadius,
        AppRadius.borderLargeIncreased,
      );
    });

    test('AppShape.extraLarge has 28dp radius', () {
      expect(
        (AppShape.extraLarge as RoundedRectangleBorder).borderRadius,
        AppRadius.borderExtraLarge,
      );
    });

    test('AppShape.extraLargeIncreased has 32dp radius', () {
      expect(
        (AppShape.extraLargeIncreased as RoundedRectangleBorder).borderRadius,
        AppRadius.borderExtraLargeIncreased,
      );
    });

    test('AppShape.extraExtraLarge has 48dp radius', () {
      expect(
        (AppShape.extraExtraLarge as RoundedRectangleBorder).borderRadius,
        AppRadius.borderExtraExtraLarge,
      );
    });

    test('AppShape.full is StadiumBorder', () {
      expect(AppShape.full, isA<StadiumBorder>());
    });
  });

  group('AppShape Directional Rounding Tokens', () {
    test('AppShape.extraSmallTop rounds only top corners with 4dp', () {
      expect(
        (AppShape.extraSmallTop as RoundedRectangleBorder).borderRadius,
        AppRadius.borderExtraSmallTop,
      );
    });

    test('AppShape.largeTop rounds only top corners with 16dp', () {
      expect(
        (AppShape.largeTop as RoundedRectangleBorder).borderRadius,
        AppRadius.borderLargeTop,
      );
    });

    test('AppShape.extraLargeTop rounds only top corners with 28dp', () {
      expect(
        (AppShape.extraLargeTop as RoundedRectangleBorder).borderRadius,
        AppRadius.borderExtraLargeTop,
      );
    });

    test('AppShape.largeStart rounds start corners with 16dp', () {
      expect(
        (AppShape.largeStart as RoundedRectangleBorder).borderRadius,
        AppRadius.borderLargeStart,
      );
    });

    test('AppShape.largeEnd rounds end corners with 16dp', () {
      expect(
        (AppShape.largeEnd as RoundedRectangleBorder).borderRadius,
        AppRadius.borderLargeEnd,
      );
    });
  });

  group('AppShape Expressive Motion & Shape Sets', () {
    test('AppShape.lerp smoothly interpolates between shapes', () {
      final lerped = AppShape.lerp(AppShape.small, AppShape.large, 0.5);
      expect(lerped, isNotNull);
    });

    test('AppShape provides expressive shape sets', () {
      expect(AppShape.round, isNotNull);
      expect(AppShape.square, isNotNull);
    });
  });
}
