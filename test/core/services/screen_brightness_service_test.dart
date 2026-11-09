import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/services/screen_brightness_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:screen_brightness/screen_brightness.dart';

class _MockScreenBrightness extends Mock implements ScreenBrightness {}

void main() {
  group('DefaultScreenBrightnessService', () {
    late _MockScreenBrightness mockPlugin;
    late DefaultScreenBrightnessService service;

    setUp(() {
      mockPlugin = _MockScreenBrightness();
      service = DefaultScreenBrightnessService(plugin: mockPlugin);
    });

    group('currentBrightness', () {
      test('returns current application brightness from plugin', () async {
        when(() => mockPlugin.application).thenAnswer((_) async => 0.65);

        final brightness = await service.currentBrightness;

        expect(brightness, equals(0.65));
        verify(() => mockPlugin.application).called(1);
      });

      test(
        'returns fallback 1.0 when plugin throws PlatformException',
        () async {
          when(() => mockPlugin.application).thenThrow(
            PlatformException(
              code: 'UNAVAILABLE',
              message: 'Screen brightness unavailable',
            ),
          );

          final brightness = await service.currentBrightness;

          expect(brightness, equals(1.0));
        },
      );

      test('returns fallback 1.0 when plugin throws general Object', () async {
        when(
          () => mockPlugin.application,
        ).thenThrow(Exception('Native channel error'));

        final brightness = await service.currentBrightness;

        expect(brightness, equals(1.0));
      });
    });

    group('setBrightness', () {
      test(
        'sets valid brightness value clamped to plugin and returns true',
        () async {
          when(
            () => mockPlugin.setApplicationScreenBrightness(any()),
          ).thenAnswer((_) async {});

          final result = await service.setBrightness(0.75);

          expect(result, isTrue);
          verify(
            () => mockPlugin.setApplicationScreenBrightness(0.75),
          ).called(1);
        },
      );

      test('clamps value below 0.0 to 0.0 and returns true', () async {
        when(
          () => mockPlugin.setApplicationScreenBrightness(any()),
        ).thenAnswer((_) async {});

        final result = await service.setBrightness(-0.5);

        expect(result, isTrue);
        verify(() => mockPlugin.setApplicationScreenBrightness(0)).called(1);
      });

      test('clamps value above 1.0 to 1.0 and returns true', () async {
        when(
          () => mockPlugin.setApplicationScreenBrightness(any()),
        ).thenAnswer((_) async {});

        final result = await service.setBrightness(1.5);

        expect(result, isTrue);
        verify(() => mockPlugin.setApplicationScreenBrightness(1)).called(1);
      });

      test(
        'safely ignores double.nan and returns false without plugin call',
        () async {
          final result = await service.setBrightness(double.nan);

          expect(result, isFalse);
          verifyNever(() => mockPlugin.setApplicationScreenBrightness(any()));
        },
      );

      test('safely ignores double.infinity and returns false', () async {
        final result = await service.setBrightness(double.infinity);

        expect(result, isFalse);
        verifyNever(() => mockPlugin.setApplicationScreenBrightness(any()));
      });

      test(
        'safely ignores double.negativeInfinity and returns false',
        () async {
          final result = await service.setBrightness(double.negativeInfinity);

          expect(result, isFalse);
          verifyNever(() => mockPlugin.setApplicationScreenBrightness(any()));
        },
      );

      test(
        'returns false when plugin throws exception without re-throwing',
        () async {
          when(
            () => mockPlugin.setApplicationScreenBrightness(any()),
          ).thenThrow(
            PlatformException(
              code: 'ERROR',
              message: 'Failed to set brightness',
            ),
          );

          final result = await service.setBrightness(0.8);

          expect(result, isFalse);
        },
      );
    });

    group('resetBrightness', () {
      test('delegates resetApplicationScreenBrightness to plugin and returns '
          'true', () async {
        when(
          mockPlugin.resetApplicationScreenBrightness,
        ).thenAnswer((_) async {});

        final result = await service.resetBrightness();

        expect(result, isTrue);
        verify(mockPlugin.resetApplicationScreenBrightness).called(1);
      });

      test(
        'returns false when plugin throws exception without re-throwing',
        () async {
          when(mockPlugin.resetApplicationScreenBrightness).thenThrow(
            PlatformException(
              code: 'ERROR',
              message: 'Failed to reset brightness',
            ),
          );

          final result = await service.resetBrightness();

          expect(result, isFalse);
        },
      );
    });

    group('Default Constructor & Pure DI', () {
      test('instantiates with const constructor without throwing', () {
        const defaultService = DefaultScreenBrightnessService();
        expect(defaultService, isA<ScreenBrightnessService>());
      });

      test('canonicalizes const instances in memory', () {
        const service1 = DefaultScreenBrightnessService();
        const service2 = DefaultScreenBrightnessService();
        expect(identical(service1, service2), isTrue);
      });
    });
  });
}
