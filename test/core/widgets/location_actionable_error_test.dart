import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/services/app_launcher_service.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/location_actionable_error.dart';
import 'package:mocktail/mocktail.dart';

class MockAppLauncherService extends Mock implements AppLauncherService {}

void main() {
  group('LocationActionableError', () {
    late MockAppLauncherService mockLauncherService;

    setUp(() {
      mockLauncherService = MockAppLauncherService();
    });

    test(
      'serviceDisabled builds correct error data and invokes settings',
      () async {
        var dismissed = false;
        var settingsOpened = false;

        final data = LocationActionableError.serviceDisabled(
          onDismiss: () => dismissed = true,
          openLocationSettingsFn: () async {
            settingsOpened = true;
            return true;
          },
        );

        expect(data.icon, equals(KawaloVectors.gpsDisconnectedFilled));
        expect(data.title, equals('Layanan lokasi belum diaktifkan'));
        expect(data.primaryActionLabel, equals('Aktifkan lokasi'));
        expect(data.secondaryActionLabel, equals('Pilih manual'));
        expect(data.troubleshootingTips.length, equals(3));

        data.onPrimaryAction?.call();
        expect(settingsOpened, isTrue);

        data.onSecondaryAction?.call();
        expect(dismissed, isTrue);
      },
    );

    test('serviceDisabled invokes launcherService when openLocationSettingsFn '
        'is null', () async {
      when(
        () => mockLauncherService.openLocationSettings(),
      ).thenAnswer((_) async => true);

      final data = LocationActionableError.serviceDisabled(
        onDismiss: () {},
        launcherService: mockLauncherService,
      );

      data.onPrimaryAction?.call();
      verify(() => mockLauncherService.openLocationSettings()).called(1);
    });

    test(
      'permissionDenied builds actionable error data with retry and dismiss',
      () {
        var dismissed = false;
        var retried = false;

        final data = LocationActionableError.permissionDenied(
          onDismiss: () => dismissed = true,
          onRetry: () => retried = true,
        );

        expect(data.icon, equals(KawaloVectors.location01Filled));
        expect(data.title, equals('Izin akses lokasi dibutuhkan'));
        expect(data.primaryActionLabel, equals('Izinkan akses'));
        expect(data.secondaryActionLabel, equals('Pilih manual'));
        expect(data.troubleshootingTips.length, equals(3));

        data.onPrimaryAction?.call();
        expect(retried, isTrue);

        data.onSecondaryAction?.call();
        expect(dismissed, isTrue);
      },
    );

    test('permissionDeniedForever builds correct error data and invokes app '
        'settings', () async {
      var dismissed = false;
      var appSettingsOpened = false;

      final data = LocationActionableError.permissionDeniedForever(
        onDismiss: () => dismissed = true,
        openAppSettingsFn: () async {
          appSettingsOpened = true;
          return true;
        },
      );

      expect(data.icon, equals(KawaloVectors.locationOffline01Filled));
      expect(data.title, equals('Izin akses lokasi dinonaktifkan'));
      expect(data.primaryActionLabel, equals('Buka pengaturan'));
      expect(data.secondaryActionLabel, equals('Pilih manual'));

      data.onPrimaryAction?.call();
      expect(appSettingsOpened, isTrue);

      data.onSecondaryAction?.call();
      expect(dismissed, isTrue);
    });

    test('permissionDeniedForever invokes launcherService when '
        'openAppSettingsFn is null', () async {
      when(
        () => mockLauncherService.openAppSettings(),
      ).thenAnswer((_) async => true);

      final data = LocationActionableError.permissionDeniedForever(
        onDismiss: () {},
        launcherService: mockLauncherService,
      );

      data.onPrimaryAction?.call();
      verify(() => mockLauncherService.openAppSettings()).called(1);
    });

    test('preciseLocationRequired builds correct error data and invokes app '
        'settings', () async {
      var dismissed = false;
      var appSettingsOpened = false;

      final data = LocationActionableError.preciseLocationRequired(
        onDismiss: () => dismissed = true,
        openAppSettingsFn: () async {
          appSettingsOpened = true;
          return true;
        },
      );

      expect(data.icon, equals(KawaloVectors.location01Filled));
      expect(data.title, equals('Akses lokasi presisi diperlukan'));
      expect(data.primaryActionLabel, equals('Buka pengaturan'));
      expect(data.secondaryActionLabel, equals('Pilih manual'));
      expect(data.troubleshootingTips.length, equals(4));

      data.onPrimaryAction?.call();
      expect(appSettingsOpened, isTrue);

      data.onSecondaryAction?.call();
      expect(dismissed, isTrue);
    });

    test('preciseLocationRequired invokes launcherService when '
        'openAppSettingsFn is null', () async {
      when(
        () => mockLauncherService.openAppSettings(),
      ).thenAnswer((_) async => true);

      final data = LocationActionableError.preciseLocationRequired(
        onDismiss: () {},
        launcherService: mockLauncherService,
      );

      data.onPrimaryAction?.call();
      verify(() => mockLauncherService.openAppSettings()).called(1);
    });

    test('mockLocationDetected builds security warning error data', () {
      var retried = false;
      var dismissed = false;

      final data = LocationActionableError.mockLocationDetected(
        onDismiss: () => dismissed = true,
        onRetry: () => retried = true,
      );

      expect(data.icon, equals(KawaloVectors.shieldOffFilled));
      expect(data.title, equals('Lokasi tiruan terdeteksi'));
      expect(data.primaryActionLabel, equals('Coba lagi'));
      expect(data.secondaryActionLabel, equals('Kembali'));

      data.onPrimaryAction?.call();
      expect(retried, isTrue);

      data.onSecondaryAction?.call();
      expect(dismissed, isTrue);
    });

    testWidgets(
      'showTimeoutSnackbar displays AppSnackbar with default message and retry '
      'action',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        var retried = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      LocationActionableError.showTimeoutSnackbar(
                        context,
                        onRetry: () => retried = true,
                      );
                    },
                    child: const Text('Show Timeout'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Timeout'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Waktu deteksi lokasi habis. Pastikan berada di area terbuka.',
          ),
          findsOneWidget,
        );
        expect(find.text('Coba lagi'), findsOneWidget);

        await tester.tap(find.text('Coba lagi'));
        await tester.pumpAndSettle();

        expect(retried, isTrue);
      },
    );

    test('fromLocationResult maps each status correctly', () {
      final serviceDisabledData = LocationActionableError.fromLocationResult(
        const LocationResult.serviceDisabled(),
        onDismiss: () {},
      );
      expect(
        serviceDisabledData.title,
        equals('Layanan lokasi belum diaktifkan'),
      );

      final permDeniedData = LocationActionableError.fromLocationResult(
        const LocationResult.permissionDenied(),
        onDismiss: () {},
      );
      expect(permDeniedData.title, equals('Izin akses lokasi dibutuhkan'));

      final permForeverData = LocationActionableError.fromLocationResult(
        const LocationResult.permissionDeniedForever(),
        onDismiss: () {},
      );
      expect(permForeverData.title, equals('Izin akses lokasi dinonaktifkan'));

      final preciseData = LocationActionableError.fromLocationResult(
        const LocationResult.preciseLocationRequired(),
        onDismiss: () {},
      );
      expect(preciseData.title, equals('Akses lokasi presisi diperlukan'));
      expect(preciseData.icon, equals(KawaloVectors.location01Filled));
      expect(preciseData.troubleshootingTips.length, equals(4));

      final mockData = LocationActionableError.fromLocationResult(
        const LocationResult.mockDetected(),
        onDismiss: () {},
      );
      expect(mockData.title, equals('Lokasi tiruan terdeteksi'));

      final unexpectedData = LocationActionableError.fromLocationResult(
        const LocationResult.error('Koneksi terputus'),
        onDismiss: () {},
      );
      expect(unexpectedData.title, equals('Gagal mendeteksi lokasi'));
    });

    test('fromLocationResult throws ArgumentError when status is success', () {
      expect(
        () => LocationActionableError.fromLocationResult(
          const LocationResult(status: LocationStatus.success),
          onDismiss: () {},
        ),
        throwsArgumentError,
      );
    });

    test('fromLocationResult throws ArgumentError when status is timeout', () {
      expect(
        () => LocationActionableError.fromLocationResult(
          const LocationResult.timeout(),
          onDismiss: () {},
        ),
        throwsArgumentError,
      );
    });

    test('themeMode is propagated to AppActionableErrorData', () {
      final data = LocationActionableError.serviceDisabled(
        onDismiss: () {},
        themeMode: AppActionableErrorThemeMode.dark,
      );
      expect(data.themeMode, equals(AppActionableErrorThemeMode.dark));
    });

    testWidgets('showBottomSheet displays modal sheet with error details', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2;
      addTearDown(() => tester.view.reset());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    LocationActionableError.showBottomSheet<void>(
                      context,
                      result: const LocationResult.serviceDisabled(),
                    );
                  },
                  child: const Text('Tampilkan Error'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tampilkan Error'));
      await tester.pumpAndSettle();

      expect(find.text('Layanan lokasi belum diaktifkan'), findsOneWidget);
      expect(find.text('Aktifkan lokasi'), findsOneWidget);
      expect(find.text('Pilih manual'), findsOneWidget);

      await tester.tap(find.text('Pilih manual'));
      await tester.pumpAndSettle();

      expect(find.text('Layanan lokasi belum diaktifkan'), findsNothing);
    });
  });
}
