import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';

void main() {
  group('AppMotion Tests', () {
    test('provides duration and curve tokens', () {
      expect(AppMotion.short1, isA<Duration>());
      expect(AppMotion.long2, isA<Duration>());
      expect(AppMotion.standard, isA<Curve>());
      expect(AppMotion.emphasized, isA<Curve>());
    });

    test('creates SpringSimulation from AppMotion tokens', () {
      final simulation = AppMotion.spatialDefault.createSimulation(
        start: 100,
        end: 0,
        velocity: 10,
      );

      expect(simulation.x(0), equals(100));
      expect(simulation.dx(0), equals(10));
    });

    testWidgets('isReducedMotion respects MediaQuery setting', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: SizedBox(),
        ),
      );

      final reducedMotionActive = AppMotion.isReducedMotion(
        tester.element(find.byType(SizedBox)),
      );
      expect(reducedMotionActive, isTrue);
    });
  });
}
