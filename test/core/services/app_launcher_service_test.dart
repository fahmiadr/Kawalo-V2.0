import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kawalo_mobile/core/services/app_launcher_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:url_launcher/url_launcher.dart';

class MockGeolocatorPlatform extends Mock implements GeolocatorPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGeolocatorPlatform mockGeolocator;

  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(LaunchMode.externalApplication);
    registerFallbackValue(AppLaunchMode.externalApplication);
  });

  setUp(() {
    mockGeolocator = MockGeolocatorPlatform();
  });

  group('DefaultAppLauncherService Unit Tests', () {
    test(
      'openAppSettings delegates to geolocator and returns true on success',
      () async {
        when(
          () => mockGeolocator.openAppSettings(),
        ).thenAnswer((_) async => true);

        final service = DefaultAppLauncherService(
          geolocatorPlatform: mockGeolocator,
        );
        final result = await service.openAppSettings();

        expect(result, isTrue);
        verify(() => mockGeolocator.openAppSettings()).called(1);
      },
    );

    test(
      'openAppSettings returns false when platform throws exception',
      () async {
        when(
          () => mockGeolocator.openAppSettings(),
        ).thenThrow(Exception('Platform error'));

        final service = DefaultAppLauncherService(
          geolocatorPlatform: mockGeolocator,
        );
        final result = await service.openAppSettings();

        expect(result, isFalse);
      },
    );

    test('openLocationSettings delegates to geolocator and returns true on '
        'success', () async {
      when(
        () => mockGeolocator.openLocationSettings(),
      ).thenAnswer((_) async => true);

      final service = DefaultAppLauncherService(
        geolocatorPlatform: mockGeolocator,
      );
      final result = await service.openLocationSettings();

      expect(result, isTrue);
      verify(() => mockGeolocator.openLocationSettings()).called(1);
    });

    test(
      'openLocationSettings returns false when platform throws exception',
      () async {
        when(
          () => mockGeolocator.openLocationSettings(),
        ).thenThrow(Exception('Location settings unavailable'));

        final service = DefaultAppLauncherService(
          geolocatorPlatform: mockGeolocator,
        );
        final result = await service.openLocationSettings();

        expect(result, isFalse);
      },
    );

    test('default constructor uses GeolocatorPlatform.instance cleanly', () {
      const service = DefaultAppLauncherService();
      expect(service, isA<DefaultAppLauncherService>());
    });

    test('openMap launches cleanly when title is not provided', () async {
      Uri? launchedUri;
      final service = DefaultAppLauncherService(
        canLaunch: (url) async => true,
        launch:
            (
              url, {
              mode = LaunchMode.platformDefault,
              webOnlyWindowName,
            }) async {
              launchedUri = url;
              return true;
            },
      );

      final result = await service.openMap(
        latitude: -6.2088,
        longitude: 106.8456,
      );

      expect(result, isTrue);
      expect(launchedUri, isNotNull);
    });

    test('openMap launches Apple Maps on iOS when available', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      Uri? launchedUri;
      LaunchMode? launchedMode;

      final service = DefaultAppLauncherService(
        canLaunch: (url) async => url.host == 'maps.apple.com',
        launch:
            (
              url, {
              mode = LaunchMode.platformDefault,
              webOnlyWindowName,
            }) async {
              launchedUri = url;
              launchedMode = mode;
              return true;
            },
      );

      final result = await service.openMap(
        latitude: -6.2088,
        longitude: 106.8456,
        title: 'Gerbang Utama',
      );

      expect(result, isTrue);
      expect(launchedUri, isNotNull);
      expect(launchedUri!.host, equals('maps.apple.com'));
      expect(launchedUri!.queryParameters['q'], equals('Gerbang Utama'));
      expect(launchedUri!.queryParameters['ll'], equals('-6.2088,106.8456'));
      expect(launchedMode, equals(LaunchMode.externalApplication));
    });

    test(
      'openMap launches Android geo intent on Android when available',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        Uri? launchedUri;
        LaunchMode? launchedMode;

        final service = DefaultAppLauncherService(
          canLaunch: (url) async => url.scheme == 'geo',
          launch:
              (
                url, {
                mode = LaunchMode.platformDefault,
                webOnlyWindowName,
              }) async {
                launchedUri = url;
                launchedMode = mode;
                return true;
              },
        );

        final result = await service.openMap(
          latitude: -6.2088,
          longitude: 106.8456,
          title: 'Pos 1',
        );

        expect(result, isTrue);
        expect(launchedUri, isNotNull);
        expect(launchedUri!.scheme, equals('geo'));
        expect(launchedUri!.path, equals('-6.2088,106.8456'));
        expect(launchedUri!.query, contains('q=-6.2088,106.8456'));
        expect(launchedMode, equals(LaunchMode.externalApplication));
      },
    );

    test(
      'openMap falls back to Google Maps web when native scheme is unavailable',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        Uri? launchedUri;

        final service = DefaultAppLauncherService(
          canLaunch: (url) async => url.host == 'www.google.com',
          launch:
              (
                url, {
                mode = LaunchMode.platformDefault,
                webOnlyWindowName,
              }) async {
                launchedUri = url;
                return true;
              },
        );

        final result = await service.openMap(latitude: -6.2, longitude: 106.8);

        expect(result, isTrue);
        expect(launchedUri, isNotNull);
        expect(launchedUri!.host, equals('www.google.com'));
        expect(launchedUri!.path, equals('/maps/search/'));
      },
    );

    test('openMap handles exceptions gracefully and returns false', () async {
      final service = DefaultAppLauncherService(
        canLaunch: (url) async => throw Exception('Platform error'),
      );

      final result = await service.openMap(latitude: -6.2, longitude: 106.8);

      expect(result, isFalse);
    });

    test(
      'openMap returns false immediately when coordinates are NaN or Infinite',
      () async {
        const service = DefaultAppLauncherService();

        expect(
          await service.openMap(latitude: double.nan, longitude: 106.8),
          isFalse,
        );
        expect(
          await service.openMap(latitude: -6.2, longitude: double.nan),
          isFalse,
        );
        expect(
          await service.openMap(latitude: double.infinity, longitude: 106.8),
          isFalse,
        );
        expect(
          await service.openMap(
            latitude: -6.2,
            longitude: double.negativeInfinity,
          ),
          isFalse,
        );
      },
    );

    test(
      'openMap returns false when coordinates exceed Earth physical bounds',
      () async {
        const service = DefaultAppLauncherService();

        expect(
          await service.openMap(latitude: 90.1, longitude: 106.8),
          isFalse,
        );
        expect(
          await service.openMap(latitude: -90.1, longitude: 106.8),
          isFalse,
        );
        expect(await service.openMap(latitude: 0, longitude: 180.1), isFalse);
        expect(await service.openMap(latitude: 0, longitude: -180.1), isFalse);
      },
    );

    test('openBrowser launches url with externalApplication mode', () async {
      Uri? capturedUri;
      LaunchMode? capturedMode;

      final service = DefaultAppLauncherService(
        canLaunch: (url) async => true,
        launch:
            (
              url, {
              mode = LaunchMode.platformDefault,
              webOnlyWindowName,
            }) async {
              capturedUri = url;
              capturedMode = mode;
              return true;
            },
      );

      final targetUrl = Uri.parse('https://kawalo.example.com/panduan');
      final result = await service.openBrowser(targetUrl);

      expect(result, isTrue);
      expect(capturedUri, equals(targetUrl));
      expect(capturedMode, equals(LaunchMode.externalApplication));
    });

    test('openBrowser correctly maps all AppLaunchMode values', () async {
      LaunchMode? capturedMode;

      final service = DefaultAppLauncherService(
        canLaunch: (url) async => true,
        launch:
            (
              url, {
              mode = LaunchMode.platformDefault,
              webOnlyWindowName,
            }) async {
              capturedMode = mode;
              return true;
            },
      );

      final url = Uri.parse('https://kawalo.example.com');

      await service.openBrowser(url, mode: AppLaunchMode.platformDefault);
      expect(capturedMode, equals(LaunchMode.platformDefault));

      await service.openBrowser(url, mode: AppLaunchMode.inAppWebView);
      expect(capturedMode, equals(LaunchMode.inAppWebView));

      await service.openBrowser(url);
      expect(capturedMode, equals(LaunchMode.externalApplication));

      await service.openBrowser(url, mode: AppLaunchMode.inAppBrowserView);
      expect(capturedMode, equals(LaunchMode.inAppBrowserView));
    });

    test(
      'openBrowser returns false immediately when URI has no scheme',
      () async {
        var launchCalled = false;
        final service = DefaultAppLauncherService(
          canLaunch: (url) async => true,
          launch:
              (
                url, {
                mode = LaunchMode.platformDefault,
                webOnlyWindowName,
              }) async {
                launchCalled = true;
                return true;
              },
        );

        final schemeless = Uri(path: 'kawalo.example.com/panduan');
        final emptyScheme = Uri(scheme: '', path: 'panduan');

        expect(await service.openBrowser(schemeless), isFalse);
        expect(await service.openBrowser(emptyScheme), isFalse);
        expect(launchCalled, isFalse);
      },
    );

    test('openBrowser returns false when canLaunch is false', () async {
      var launchCalled = false;

      final service = DefaultAppLauncherService(
        canLaunch: (url) async => false,
        launch:
            (
              url, {
              mode = LaunchMode.platformDefault,
              webOnlyWindowName,
            }) async {
              launchCalled = true;
              return true;
            },
      );

      final result = await service.openBrowser(
        Uri.parse('https://invalid.url'),
      );

      expect(result, isFalse);
      expect(launchCalled, isFalse);
    });

    test('openBrowser returns false when launch throws exception', () async {
      final service = DefaultAppLauncherService(
        canLaunch: (url) async => true,
        launch:
            (
              url, {
              mode = LaunchMode.platformDefault,
              webOnlyWindowName,
            }) async {
              throw Exception('ActivityNotFound');
            },
      );

      final result = await service.openBrowser(Uri.parse('https://broken.url'));

      expect(result, isFalse);
    });

    test('openDialer formats and launches tel: URI cleanly', () async {
      Uri? capturedUri;

      final service = DefaultAppLauncherService(
        canLaunch: (url) async => true,
        launch:
            (
              url, {
              mode = LaunchMode.platformDefault,
              webOnlyWindowName,
            }) async {
              capturedUri = url;
              return true;
            },
      );

      final result = await service.openDialer('+62 (021) 555-0199');

      expect(result, isTrue);
      expect(capturedUri, isNotNull);
      expect(capturedUri!.scheme, equals('tel'));
      expect(capturedUri!.path, equals('+620215550199'));
    });

    test(
      'openEmail formats and launches mailto: URI with subject and body',
      () async {
        Uri? capturedUri;

        final service = DefaultAppLauncherService(
          canLaunch: (url) async => true,
          launch:
              (
                url, {
                mode = LaunchMode.platformDefault,
                webOnlyWindowName,
              }) async {
                capturedUri = url;
                return true;
              },
        );

        final result = await service.openEmail(
          'bantuan@kawalo.id',
          subject: 'Laporan Kendala',
          body: 'Berikut rincian kendala yang terjadi.',
        );

        expect(result, isTrue);
        expect(capturedUri, isNotNull);
        expect(capturedUri!.scheme, equals('mailto'));
        expect(capturedUri!.path, equals('bantuan@kawalo.id'));
        expect(
          capturedUri!.queryParameters['subject'],
          equals('Laporan Kendala'),
        );
        expect(
          capturedUri!.queryParameters['body'],
          equals('Berikut rincian kendala yang terjadi.'),
        );
      },
    );

    test(
      'openDialer returns false when sanitized phone number is invalid',
      () async {
        const service = DefaultAppLauncherService();

        expect(await service.openDialer(''), isFalse);
        expect(await service.openDialer('   '), isFalse);
        expect(await service.openDialer('abc-xyz'), isFalse);
        expect(await service.openDialer('+'), isFalse);
        expect(await service.openDialer('+++'), isFalse);
        expect(await service.openDialer('+abc'), isFalse);
      },
    );

    test(
      'openEmail returns false when email address is blank or invalid',
      () async {
        const service = DefaultAppLauncherService();

        expect(await service.openEmail(''), isFalse);
        expect(await service.openEmail('   '), isFalse);
        expect(await service.openEmail('bukan-email'), isFalse);
        expect(await service.openEmail('user@'), isFalse);
        expect(await service.openEmail('@domain.com'), isFalse);
      },
    );
  });
}
