import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_fab.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_map_picker_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:mocktail/mocktail.dart';

class MockReverseGeocodeService extends Mock implements ReverseGeocodeService {}

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: child,
    );
  }

  Finder findAddressShimmer() => find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Memuat alamat lokasi',
      );

  group('AppMapPickerDialog Widget Tests', () {
    late MockReverseGeocodeService mockGeocodeService;

    setUp(() {
      mockGeocodeService = MockReverseGeocodeService();
      when(
        () => mockGeocodeService.reverseGeocode(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => const ReverseGeocodeResult.success(
          latitude: -6.2088,
          longitude: 106.8456,
          address: 'Jl. Kebon Jeruk No. 12',
        ),
      );
    });

    testWidgets(
      'renders map, GPS button with gps01 vector, and coordinates without icon',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        when(
          () => mockGeocodeService.reverseGeocode(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => const ReverseGeocodeResult.success(
            latitude: -6.2088,
            longitude: 106.8456,
            address: 'Jl. Kebon Jeruk No. 12',
          ),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              initialLatitude: -6.2088,
              initialLongitude: 106.8456,
              initialAddress: 'Alamat Awal',
              reverseGeocodeService: mockGeocodeService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Kanvas FlutterMap terpasang
        expect(find.byType(FlutterMap), findsOneWidget);

        // 2. FAB GPS menggunakan AppFab berukuran medium dengan
        // KawaloVectors.gps01
        final fabFinder = find.byType(AppFab);
        expect(fabFinder, findsOneWidget);
        final appFab = tester.widget<AppFab>(fabFinder);
        expect(appFab.size, equals(AppFabSize.regular));
        final gpsSvgFinder = find.descendant(
          of: fabFinder,
          matching: find.byWidgetPredicate(
            (w) => w is AppSvgIcon && w.assetPath == KawaloVectors.gps01,
          ),
        );
        expect(gpsSvgFinder, findsOneWidget);

        // 3. Teks Koordinat muncul
        expect(
          find.text('Koordinat: -6.208800, 106.845600'),
          findsOneWidget,
        );

        // 4. Pastikan teks konfirmasi tombol muncul
        expect(
          find.text('Pilih titik ini'),
          findsOneWidget,
        );

        // 5. Penanda titik pusat peta menggunakan custom shape M3 dan
        // ground dot
        final pinCustomPaintFinder = find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.size == const Size(32, 42) &&
              w.painter != null &&
              w.painter.runtimeType.toString() == '_MapPinPainter',
        );
        expect(pinCustomPaintFinder, findsOneWidget);

        final dotFinder = find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.constraints?.maxWidth == 8 &&
              w.constraints?.maxHeight == 8 &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle,
        );
        expect(dotFinder, findsOneWidget);
      },
    );

    testWidgets(
      'confirms selected coordinates and pops AppMapPickerResult',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        AppMapPickerResult? result;

        await tester.pumpWidget(
          buildTestableWidget(
            Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      result = await AppMapPickerDialog.show(
                        context,
                        initialLatitude: -6.1754,
                        initialLongitude: 106.8272,
                        initialAddress: 'Monas, Jakarta',
                        reverseGeocodeService: mockGeocodeService,
                      );
                    },
                    child: const Text('Buka Dialog'),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Buka dialog
        await tester.tap(find.text('Buka Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Pilih di peta'), findsOneWidget);
        expect(
          find.text('Koordinat: -6.175400, 106.827200'),
          findsOneWidget,
        );

        // Tekan tombol konfirmasi
        final confirmButton = find.widgetWithText(AppButton, 'Pilih titik ini');
        expect(confirmButton, findsOneWidget);
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();

        // Dialog tertutup dan result terisi
        expect(find.text('Pilih di peta'), findsNothing);
        expect(result, isNotNull);
        expect(result!.latitude, equals(-6.1754));
        expect(result!.longitude, equals(106.8272));
        expect(result!.address, equals('Monas, Jakarta'));
      },
    );

    testWidgets(
      'pops without result when close button is tapped',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        AppMapPickerResult? result = const AppMapPickerResult(
          latitude: 0,
          longitude: 0,
        );

        await tester.pumpWidget(
          buildTestableWidget(
            Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      result = await AppMapPickerDialog.show(
                        context,
                        initialLatitude: -6.1754,
                        initialLongitude: 106.8272,
                        reverseGeocodeService: mockGeocodeService,
                      );
                    },
                    child: const Text('Buka Dialog'),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Buka Dialog'));
        await tester.pumpAndSettle();

        // Tutup via tombol close
        await tester.tap(find.bySemanticsLabel('Tutup'));
        await tester.pumpAndSettle();

        expect(result, isNull);
      },
    );

    testWidgets(
      'acquires GPS position and confirms selected location when GPS FAB '
      'is tapped with null initial coordinates',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        const gpsLat = -7.250445;
        const gpsLng = 112.768845;
        final mockGpsPosition = Position(
          latitude: gpsLat,
          longitude: gpsLng,
          timestamp: DateTime.now(),
          accuracy: 5,
          altitude: 10,
          altitudeAccuracy: 5,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );

        when(
          () => mockGeocodeService.reverseGeocode(
            latitude: gpsLat,
            longitude: gpsLng,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => const ReverseGeocodeResult.success(
            latitude: gpsLat,
            longitude: gpsLng,
            address: 'Jl. Tunjungan No. 1, Surabaya',
          ),
        );

        AppMapPickerResult? result;

        await tester.pumpWidget(
          buildTestableWidget(
            Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      result = await AppMapPickerDialog.show(
                        context,
                        reverseGeocodeService: mockGeocodeService,
                        locationProvider: () async =>
                            LocationResult.success(mockGpsPosition),
                      );
                    },
                    child: const Text('Buka Dialog'),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Buka Dialog'));
        await tester.pumpAndSettle();

        // Pengguna mengetuk tombol GPS FAB untuk mendeteksi lokasi saat ini
        await tester.tap(find.byType(AppFab));
        await tester.pumpAndSettle();

        // Majukan timer debounce reverse geocoding (650ms)
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        // Titik terdeteksi sesuai posisi GPS pengguna setelah tombol
        // GPS ditekan
        expect(
          find.text('Koordinat: -7.250445, 112.768845'),
          findsOneWidget,
        );
        expect(
          find.text('Jl. Tunjungan No. 1, Surabaya'),
          findsOneWidget,
        );

        // Konfirmasi titik lokasi GPS
        await tester.tap(find.widgetWithText(AppButton, 'Pilih titik ini'));
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!.latitude, equals(gpsLat));
        expect(result!.longitude, equals(gpsLng));
        expect(result!.address, equals('Jl. Tunjungan No. 1, Surabaya'));
      },
    );

    testWidgets(
      'falls back to default coordinates when GPS fails and initial '
      'coordinates are null',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              reverseGeocodeService: mockGeocodeService,
              locationProvider: () async =>
                  const LocationResult.serviceDisabled(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tetap menggunakan koordinat default (Jakarta) secara aman tanpa crash
        expect(
          find.text('Koordinat: -6.208800, 106.845600'),
          findsOneWidget,
        );

        // Tombol konfirmasi harus disabled saat tidak ada fix GPS atau input
        final confirmButton = tester.widget<AppButton>(
          find.widgetWithText(AppButton, 'Pilih titik ini'),
        );
        expect(confirmButton.onPressed, isNull);
      },
    );

    testWidgets(
      'uses lastKnownLocationProvider as camera viewport hint while confirm '
      'button remains disabled until fresh GPS succeeds',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        const cachedLat = -7.797068;
        const cachedLng = 110.370529;
        final cachedPosition = Position(
          latitude: cachedLat,
          longitude: cachedLng,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          accuracy: 10,
          altitude: 100,
          altitudeAccuracy: 10,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );

        final freshGpsCompleter = Completer<LocationResult>();

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              reverseGeocodeService: mockGeocodeService,
              lastKnownLocationProvider: () async => cachedPosition,
              locationProvider: () => freshGpsCompleter.future,
            ),
          ),
        );
        await tester.pump();

        // Kamera awal berpusat pada koordinat cache sebagai viewport hint
        expect(
          find.text('Koordinat: -7.797068, 110.370529'),
          findsOneWidget,
        );

        // Tombol konfirmasi dinonaktifkan karena cache bukan titik
        // terkonfirmasi
        var confirmButton = tester.widget<AppButton>(
          find.widgetWithText(AppButton, 'Pilih titik ini'),
        );
        expect(confirmButton.onPressed, isNull);

        // Pengguna mengetuk FAB GPS untuk memicu deteksi posisi
        await tester.tap(find.byType(AppFab));
        await tester.pump();

        // Ketika fresh GPS berhasil mendapatkan posisi baru
        const freshLat = -7.795000;
        const freshLng = 110.365000;
        freshGpsCompleter.complete(
          LocationResult.success(
            Position(
              latitude: freshLat,
              longitude: freshLng,
              timestamp: DateTime.now(),
              accuracy: 3,
              altitude: 100,
              altitudeAccuracy: 3,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Koordinat terupdate ke posisi fresh GPS
        expect(
          find.text('Koordinat: -7.795000, 110.365000'),
          findsOneWidget,
        );

        // Tombol konfirmasi sekarang aktif
        confirmButton = tester.widget<AppButton>(
          find.widgetWithText(AppButton, 'Pilih titik ini'),
        );
        expect(confirmButton.onPressed, isNotNull);
      },
    );

    testWidgets(
      'does not use cached position as fallback if fresh GPS fails, and '
      'enables confirm button once user manually interacts',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        const cachedLat = -7.797068;
        const cachedLng = 110.370529;
        final cachedPosition = Position(
          latitude: cachedLat,
          longitude: cachedLng,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          accuracy: 10,
          altitude: 100,
          altitudeAccuracy: 10,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              reverseGeocodeService: mockGeocodeService,
              lastKnownLocationProvider: () async => cachedPosition,
              locationProvider: () async =>
                  const LocationResult.permissionDenied(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Kamera tetap di hint viewport cache
        expect(
          find.text('Koordinat: -7.797068, 110.370529'),
          findsOneWidget,
        );

        // Tombol konfirmasi tetap nonaktif karena cache DILARANG jadi fallback
        var confirmButton = tester.widget<AppButton>(
          find.widgetWithText(AppButton, 'Pilih titik ini'),
        );
        expect(confirmButton.onPressed, isNull);

        // Pengguna mengetuk 'Pilih manual' pada lembar galat yang
        // muncul otomatis
        expect(find.text('Pilih manual'), findsOneWidget);
        await tester.tap(find.text('Pilih manual'));
        await tester.pumpAndSettle();

        // Pengguna menggeser (drag) peta secara manual
        await tester.drag(find.byType(FlutterMap), const Offset(0, -60));
        await tester.pumpAndSettle();

        // Tombol konfirmasi aktif karena pengguna telah memilih titik manual
        confirmButton = tester.widget<AppButton>(
          find.widgetWithText(AppButton, 'Pilih titik ini'),
        );
        expect(confirmButton.onPressed, isNotNull);
      },
    );

    testWidgets(
      'does not trigger auto-detect GPS on initial load when autoTriggerGps is '
      'false and keeps GPS button idle until tapped',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        var locationProviderCalled = false;

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              autoTriggerGps: false,
              reverseGeocodeService: mockGeocodeService,
              locationProvider: () async {
                locationProviderCalled = true;
                return const LocationResult.serviceDisabled();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verifikasi location provider TIDAK dipanggil otomatis saat buka
        expect(locationProviderCalled, isFalse);

        // 2. Verifikasi tidak ada snackbar peringatan yang muncul
        expect(
          find.text(
            'GPS perangkat belum aktif. Geser peta atau aktifkan lokasi.',
          ),
          findsNothing,
        );

        // 3. Tombol FAB GPS tidak sedang dalam status loading
        final fabFinder = find.byType(AppFab);
        expect(
          find.descendant(
            of: fabFinder,
            matching: find.byType(AppLoadingIndicator),
          ),
          findsNothing,
        );

        // 4. Tombol konfirmasi dinonaktifkan
        final confirmButton = tester.widget<AppButton>(
          find.widgetWithText(AppButton, 'Pilih titik ini'),
        );
        expect(confirmButton.onPressed, isNull);

        // 5. In-card guiding helper muncul
        expect(
          find.text('Geser peta untuk menentukan titik secara manual'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows in-card guiding helper when location is unconfirmed and hides '
      'it when map is dragged',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              autoTriggerGps: false,
              reverseGeocodeService: mockGeocodeService,
              locationProvider: () async =>
                  const LocationResult.serviceDisabled(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // In-card helper muncul karena belum ada titik yang dikonfirmasi
        expect(
          find.text('Geser peta untuk menentukan titik secara manual'),
          findsOneWidget,
        );

        // Pengguna menggeser peta
        await tester.drag(find.byType(FlutterMap), const Offset(0, -60));
        await tester.pumpAndSettle();

        // In-card helper menghilang setelah interaksi sadar pengguna
        expect(
          find.text('Geser peta untuk menentukan titik secara manual'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'explicit tap on GPS FAB when serviceDisabled opens actionable bottom '
      'sheet and triggers openLocationSettingsFn',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        var settingsTriggered = false;

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              initialLatitude: -6.2088,
              initialLongitude: 106.8456,
              reverseGeocodeService: mockGeocodeService,
              locationProvider: () async =>
                  const LocationResult.serviceDisabled(),
              openLocationSettingsFn: () async {
                settingsTriggered = true;
                return true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Ketuk tombol GPS FAB
        await tester.tap(find.byType(AppFab));
        await tester.pumpAndSettle();

        // Modal BottomSheet AppActionableError muncul
        expect(find.text('Layanan lokasi belum diaktifkan'), findsOneWidget);
        expect(find.text('Aktifkan lokasi'), findsOneWidget);
        expect(find.text('Pilih manual'), findsOneWidget);

        // Ketuk tombol aksi 'Aktifkan lokasi'
        await tester.tap(find.widgetWithText(AppButton, 'Aktifkan lokasi'));
        await tester.pumpAndSettle();

        // Mengetuk tombol solusi TIDAK langsung menutup bottom sheet
        expect(settingsTriggered, isTrue);
        expect(find.text('Layanan lokasi belum diaktifkan'), findsOneWidget);
      },
    );

    testWidgets(
      'explicit tap on GPS FAB when permissionDeniedForever opens actionable '
      'bottom sheet and triggers openAppSettingsFn',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        var appSettingsTriggered = false;

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              initialLatitude: -6.2088,
              initialLongitude: 106.8456,
              reverseGeocodeService: mockGeocodeService,
              locationProvider: () async =>
                  const LocationResult.permissionDeniedForever(),
              openAppSettingsFn: () async {
                appSettingsTriggered = true;
                return true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(AppFab));
        await tester.pumpAndSettle();

        expect(find.text('Izin akses lokasi dinonaktifkan'), findsOneWidget);
        expect(find.text('Buka pengaturan'), findsOneWidget);

        await tester.tap(find.widgetWithText(AppButton, 'Buka pengaturan'));
        await tester.pumpAndSettle();

        expect(appSettingsTriggered, isTrue);

        // Mengetuk tombol Buka pengaturan TIDAK langsung menutup bottom sheet
        expect(find.text('Izin akses lokasi dinonaktifkan'), findsOneWidget);
      },
    );

    testWidgets(
      'explicit tap on GPS FAB when permissionDenied opens actionable '
      'bottom sheet and retries on "Izinkan akses"',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        var callCount = 0;
        Future<LocationResult> testLocationProvider() async {
          callCount++;
          if (callCount == 1) {
            return const LocationResult.permissionDenied();
          }
          return LocationResult.success(
            Position(
              latitude: -6.1754,
              longitude: 106.8272,
              timestamp: DateTime.now(),
              accuracy: 5,
              altitude: 10,
              altitudeAccuracy: 1,
              heading: 0,
              headingAccuracy: 1,
              speed: 0,
              speedAccuracy: 1,
            ),
          );
        }

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              initialLatitude: -6.2088,
              initialLongitude: 106.8456,
              reverseGeocodeService: mockGeocodeService,
              locationProvider: testLocationProvider,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Ketuk tombol GPS FAB
        await tester.tap(find.byType(AppFab));
        await tester.pumpAndSettle();

        // 2. Lembar bawah kesalahan terarah muncul dengan tombol aksi
        expect(find.text('Izin akses lokasi dibutuhkan'), findsOneWidget);
        expect(find.text('Izinkan akses'), findsOneWidget);
        expect(find.text('Pilih manual'), findsOneWidget);

        // 3. Ketuk tombol aksi primer 'Izinkan akses'
        await tester.tap(find.widgetWithText(AppButton, 'Izinkan akses'));
        await tester.pumpAndSettle();

        // 4. Modal tertutup & lokasi GPS berhasil didapat pada percobaan ulang
        expect(find.text('Izin akses lokasi dibutuhkan'), findsNothing);
        expect(callCount, equals(2));
        expect(
          find.text('Koordinat: -6.175400, 106.827200'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'explicit tap on "Izinkan akses" keeps bottom sheet open when '
      'permission is still denied',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        var callCount = 0;
        Future<LocationResult> testLocationProvider() async {
          callCount++;
          return const LocationResult.permissionDenied();
        }

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              initialLatitude: -6.2088,
              initialLongitude: 106.8456,
              reverseGeocodeService: mockGeocodeService,
              locationProvider: testLocationProvider,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(AppFab));
        await tester.pumpAndSettle();

        expect(find.text('Izin akses lokasi dibutuhkan'), findsOneWidget);

        // Ketuk tombol aksi primer 'Izinkan akses'
        await tester.tap(find.widgetWithText(AppButton, 'Izinkan akses'));
        await tester.pumpAndSettle();

        // Izin masih ditolak: bottom sheet TETAP terbuka di layar
        expect(callCount, equals(2));
        expect(find.text('Izin akses lokasi dibutuhkan'), findsOneWidget);
      },
    );

    testWidgets(
      'explicit tap on GPS FAB when timeout shows AppSnackbar with '
      'action Coba lagi',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        var retryTriggered = false;

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              initialLatitude: -6.2088,
              initialLongitude: 106.8456,
              reverseGeocodeService: mockGeocodeService,
              locationProvider: () async {
                if (retryTriggered) {
                  return LocationResult.success(
                    Position(
                      latitude: -6.1754,
                      longitude: 106.8272,
                      timestamp: DateTime.now(),
                      accuracy: 5,
                      altitude: 10,
                      altitudeAccuracy: 1,
                      heading: 0,
                      headingAccuracy: 1,
                      speed: 0,
                      speedAccuracy: 1,
                    ),
                  );
                }
                return const LocationResult.timeout();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Ketuk tombol GPS FAB
        await tester.tap(find.byType(AppFab));
        await tester.pumpAndSettle();

        // 2. AppSnackbar muncul (bukan modal bottom sheet)
        expect(
          find.text(
            'Waktu deteksi lokasi habis. Pastikan berada di area terbuka.',
          ),
          findsOneWidget,
        );
        expect(find.text('Waktu deteksi lokasi habis'), findsNothing);
        expect(find.text('Coba lagi'), findsOneWidget);

        // 3. Ketuk 'Coba lagi' pada snackbar
        retryTriggered = true;
        await tester.tap(find.text('Coba lagi'));
        await tester.pumpAndSettle();

        // 4. Berhasil memperoleh lokasi pada percobaan ulang
        expect(
          find.text('Koordinat: -6.175400, 106.827200'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'explicit tap on GPS FAB when unexpected exception is thrown catches '
      'error and opens actionable bottom sheet without crash',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        var callCount = 0;

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              initialLatitude: -6.2088,
              initialLongitude: 106.8456,
              reverseGeocodeService: mockGeocodeService,
              locationProvider: () async {
                callCount++;
                if (callCount == 1) {
                  throw Exception('Low-level platform crash');
                }
                return LocationResult.success(
                  Position(
                    latitude: -6.1754,
                    longitude: 106.8272,
                    timestamp: DateTime.now(),
                    accuracy: 5,
                    altitude: 10,
                    altitudeAccuracy: 1,
                    heading: 0,
                    headingAccuracy: 1,
                    speed: 0,
                    speedAccuracy: 1,
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Ketuk tombol GPS FAB
        await tester.tap(find.byType(AppFab));
        await tester.pumpAndSettle();

        // 2. Exception tertangkap dan modal lembar bawah ditampilkan
        expect(find.text('Gagal mendeteksi lokasi'), findsOneWidget);
        expect(find.text('Coba lagi'), findsOneWidget);
        expect(find.text('Pilih manual'), findsOneWidget);

        // 3. Ketuk 'Coba lagi'
        await tester.tap(find.widgetWithText(AppButton, 'Coba lagi'));
        await tester.pumpAndSettle();

        // 4. Modal tertutup dan lokasi berhasil diperoleh
        expect(find.text('Gagal mendeteksi lokasi'), findsNothing);
        expect(callCount, equals(2));
        expect(
          find.text('Koordinat: -6.175400, 106.827200'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'does not show address shimmer during GPS locating, and shows it '
      'only when reverse geocoding after point moves',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        final gpsCompleter = Completer<LocationResult>();
        final geocodeCompleter = Completer<ReverseGeocodeResult>();

        when(
          () => mockGeocodeService.reverseGeocode(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) => geocodeCompleter.future);

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              autoTriggerGps: false,
              reverseGeocodeService: mockGeocodeService,
              locationProvider: () => gpsCompleter.future,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Ketuk tombol FAB GPS untuk memicu pendeteksian lokasi
        await tester.tap(find.byType(AppFab));
        await tester.pump();

        // 1. FAB GPS sedang loading
        final fabFinder = find.byType(AppFab);
        expect(
          find.descendant(
            of: fabFinder,
            matching: find.byType(AppLoadingIndicator),
          ),
          findsOneWidget,
        );

        // 2. Kartu alamat TIDAK boleh menampilkan loading saat proses GPS
        expect(findAddressShimmer(), findsNothing);
        expect(find.text('Mencari alamat...'), findsNothing);
        expect(find.text('Mendeteksi lokasi GPS...'), findsNothing);
        expect(find.text('Mencari alamat jalan...'), findsNothing);

        // 3. Selesaikan proses GPS dan pindahkan titik kamera
        const gpsLat = -7.250445;
        const gpsLng = 112.768845;
        gpsCompleter.complete(
          LocationResult.success(
            Position(
              latitude: gpsLat,
              longitude: gpsLng,
              timestamp: DateTime.now(),
              accuracy: 5,
              altitude: 10,
              altitudeAccuracy: 5,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            ),
          ),
        );
        await tester.pump();

        // 4. Setelah titik selesai berpindah, shimmer skeleton alamat dimulai
        expect(findAddressShimmer(), findsOneWidget);

        // 5. Selesaikan geocoding
        geocodeCompleter.complete(
          const ReverseGeocodeResult.success(
            latitude: -7.2575,
            longitude: 112.7521,
            address: 'Jl. Pemuda No. 10, Surabaya',
          ),
        );
        await tester.pumpAndSettle();

        expect(findAddressShimmer(), findsNothing);
        expect(find.text('Jl. Pemuda No. 10, Surabaya'), findsOneWidget);
      },
    );

    testWidgets(
      'preserves 3-line area with maxLines 3 and prevents layout shift',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        const testAddress =
            'Jl. Jenderal Sudirman No. Kav 52-53, RT.5/RW.3, Senayan, '
            'Kebayoran Baru, Kota Jakarta Selatan, Daerah Khusus Ibukota '
            'Jakarta 12190';

        when(
          () => mockGeocodeService.reverseGeocode(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => const ReverseGeocodeResult.success(
            latitude: -6.2255,
            longitude: 106.8085,
            address: testAddress,
          ),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              initialLatitude: -6.2255,
              initialLongitude: 106.8085,
              initialAddress: testAddress,
              reverseGeocodeService: mockGeocodeService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Pastikan teks alamat memiliki maxLines 3 dan TextOverflow.ellipsis
        final addressFinder = find.text(testAddress);
        expect(addressFinder, findsOneWidget);
        final addressTextWidget = tester.widget<Text>(addressFinder);
        expect(addressTextWidget.maxLines, equals(3));
        expect(addressTextWidget.overflow, equals(TextOverflow.ellipsis));

        // Letak tombol konfirmasi terverifikasi
        final buttonRect = tester.getRect(
          find.widgetWithText(AppButton, 'Pilih titik ini'),
        );
        expect(buttonRect.top, greaterThan(0));
      },
    );

    testWidgets(
      'bottom FAB and card remain fixed in position when keyboard appears',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        // Berikan safe area bawah seperti pada perangkat fisik
        // (misal gesture bar).
        tester.view.viewPadding = const FakeViewPadding(bottom: 34);
        tester.view.padding = const FakeViewPadding(bottom: 34);

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              initialLatitude: -6.2088,
              initialLongitude: 106.8456,
              reverseGeocodeService: mockGeocodeService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final cardFinder = find.byType(AppCard);
        final fabFinder = find.byType(AppFab);
        final initialCardRect = tester.getRect(cardFinder);
        final initialFabRect = tester.getRect(fabFinder);

        // Simulasikan kemunculan keyboard dengan viewInsets bottom
        // (saat keyboard muncul di perangkat fisik, padding.bottom menjadi 0).
        tester.view.viewInsets = const FakeViewPadding(bottom: 600);
        tester.view.padding = FakeViewPadding.zero;
        await tester.pumpAndSettle();

        final postKeyboardCardRect = tester.getRect(cardFinder);
        final postKeyboardFabRect = tester.getRect(fabFinder);

        // Posisi vertikal dan horizontal kartu bawah dan FAB tetap sama
        // persis dan tidak meresize jarak ke tepi bawah berkat
        // maintainBottomViewPadding.
        expect(postKeyboardCardRect, equals(initialCardRect));
        expect(postKeyboardFabRect, equals(initialFabRect));
      },
    );

    testWidgets(
      'renders precision center pin with M3 custom shape and ground dot, '
      'and lifts on movement',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              initialLatitude: -6.2088,
              initialLongitude: 106.8456,
              reverseGeocodeService: mockGeocodeService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verifikasi ground target dot (8x8) terpasang di pusat
        final dotFinder = find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.constraints?.maxWidth == 8 &&
              w.constraints?.maxHeight == 8 &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle,
        );
        expect(dotFinder, findsOneWidget);

        // 2. Verifikasi CustomPaint dengan pin kustom terpasang
        final pinCustomPaintFinder = find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.size == const Size(32, 42) &&
              w.painter != null &&
              w.painter.runtimeType.toString() == '_MapPinPainter',
        );
        expect(pinCustomPaintFinder, findsOneWidget);

        // 3. Verifikasi posisi awal idle: translasi Y = -21
        // (ujung jarum menyentuh ground dot di Y = 0)
        final transformFinder = find.ancestor(
          of: pinCustomPaintFinder,
          matching: find.byType(Transform),
        );
        expect(transformFinder, findsWidgets);
        final initialTranslate = tester
            .widgetList<Transform>(transformFinder)
            .firstWhere((t) => t.transform.getTranslation().y != 0);
        expect(initialTranslate.transform.getTranslation().y, equals(-21));

        // 4. Geser peta untuk memicu pengangkatan pin (lift on movement)
        final mapGestureFinder = find.byType(FlutterMap);
        final gesture = await tester.startGesture(
          tester.getCenter(mapGestureFinder),
        );
        await gesture.moveBy(const Offset(0, -60));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        // Verifikasi pin terangkat ke atas mendekati Y = -29 (-21 - 8)
        final liftedTranslate = tester
            .widgetList<Transform>(transformFinder)
            .firstWhere((t) => t.transform.getTranslation().y != 0);
        expect(liftedTranslate.transform.getTranslation().y, lessThan(-23));

        // 5. Lepaskan sentuhan (gesture up)
        await gesture.up();
        await tester.pumpAndSettle();

        // Verifikasi pin mendarat kembali menyentuh ground dot (Y = -21)
        final settledTranslate = tester
            .widgetList<Transform>(transformFinder)
            .firstWhere((t) => t.transform.getTranslation().y != 0);
        expect(settledTranslate.transform.getTranslation().y, equals(-21));
      },
    );

    testWidgets(
      'displays error with retry button when address resolution fails, and '
      'retries successfully',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        final retryCompleter = Completer<ReverseGeocodeResult>();
        var callCount = 0;
        when(
          () => mockGeocodeService.reverseGeocode(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) {
          callCount++;
          if (callCount == 1) {
            return Future.value(
              const ReverseGeocodeResult.failure(
                latitude: -6.2088,
                longitude: 106.8456,
                status: ReverseGeocodeStatus.networkError,
                errorMessage: 'Network error',
              ),
            );
          }
          return retryCompleter.future;
        });

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              initialLatitude: -6.2088,
              initialLongitude: 106.8456,
              reverseGeocodeService: mockGeocodeService,
            ),
          ),
        );
        // Biarkan debounce timer (650ms) dan geocoding selesai
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        // 1. Verifikasi error text dan tombol retry muncul
        expect(
          find.textContaining('Detail alamat jalan tidak tersedia'),
          findsOneWidget,
        );
        expect(find.text('Coba lagi'), findsOneWidget);
        final reloadIconFinder = find.byWidgetPredicate(
          (w) => w is AppSvgIcon && w.assetPath == KawaloVectors.reload,
        );
        expect(reloadIconFinder, findsOneWidget);

        // 2. Klik tombol retry 'Coba lagi'
        await tester.tap(find.text('Coba lagi'));
        await tester.pump();

        // 3. Verifikasi indikator loading shimmer skeleton muncul kembali
        expect(findAddressShimmer(), findsOneWidget);

        // 4. Selesaikan request kedua
        retryCompleter.complete(
          const ReverseGeocodeResult.success(
            latitude: -6.2088,
            longitude: 106.8456,
            address: 'Jl. Kebon Jeruk No. 12',
          ),
        );
        await tester.pumpAndSettle();

        // 5. Verifikasi alamat berhasil ditampilkan dan pesan error/retry hilang
        expect(
          find.textContaining('Detail alamat jalan tidak tersedia'),
          findsNothing,
        );
        expect(find.text('Coba lagi'), findsNothing);
        expect(find.text('Jl. Kebon Jeruk No. 12'), findsOneWidget);
      },
    );

    testWidgets(
      'prevents race conditions when subsequent geocoding finishes before '
      'earlier geocoding',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        final firstRequestCompleter = Completer<ReverseGeocodeResult>();
        final secondRequestCompleter = Completer<ReverseGeocodeResult>();
        var requestCount = 0;

        when(
          () => mockGeocodeService.reverseGeocode(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) {
          requestCount++;
          if (requestCount == 1) {
            return firstRequestCompleter.future;
          }
          return secondRequestCompleter.future;
        });

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              initialLatitude: -6.2088,
              initialLongitude: 106.8456,
              reverseGeocodeService: mockGeocodeService,
            ),
          ),
        );
        // Biarkan debounce timer (650ms) memicu request pertama
        await tester.pump(const Duration(milliseconds: 700));
        expect(requestCount, equals(1));

        // Pengguna menggeser peta untuk memicu request kedua
        await tester.drag(find.byType(FlutterMap), const Offset(0, -100));
        await tester.pump(const Duration(milliseconds: 700));
        expect(requestCount, equals(2));

        // Selesaikan request kedua terlebih dahulu (misal: lebih cepat)
        secondRequestCompleter.complete(
          const ReverseGeocodeResult.success(
            latitude: -6.2088,
            longitude: 106.8456,
            address: 'Alamat Baru Titik B',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Alamat Baru Titik B'), findsOneWidget);

        // Sekarang selesaikan request pertama yang datang terlambat
        firstRequestCompleter.complete(
          const ReverseGeocodeResult.success(
            latitude: -6.2088,
            longitude: 106.8456,
            address: 'Alamat Usang Titik A',
          ),
        );
        await tester.pumpAndSettle();

        // Alamat kedua TIDAK tertimpa oleh alamat pertama yang terlambat
        expect(find.text('Alamat Baru Titik B'), findsOneWidget);
        expect(find.text('Alamat Usang Titik A'), findsNothing);
      },
    );

    testWidgets(
      'updates coordinate text in real time during drag gesture',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              initialLatitude: -6.2088,
              initialLongitude: 106.8456,
              initialAddress: 'Alamat Awal',
              reverseGeocodeService: mockGeocodeService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Koordinat: -6.208800, 106.845600'),
          findsOneWidget,
        );

        // Lakukan gesture drag pada peta
        await tester.drag(find.byType(FlutterMap), const Offset(0, -50));
        await tester.pump();

        // Koordinat teks langsung berubah seketika tanpa menunggu debounce
        expect(
          find.text('Koordinat: -6.208800, 106.845600'),
          findsNothing,
        );
        expect(
          find.byWidgetPredicate(
            (w) => w is Text && (w.data?.startsWith('Koordinat: ') ?? false),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'automatically self-heals via AppLifecycleState.resumed when GPS is '
      'enabled after returning from OS settings',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        var isGpsTurnedOnInSettings = false;

        Future<LocationResult> testLocationProvider() async {
          if (!isGpsTurnedOnInSettings) {
            return const LocationResult.serviceDisabled();
          }
          return LocationResult.success(
            Position(
              latitude: -6.1754,
              longitude: 106.8272,
              timestamp: DateTime.now(),
              accuracy: 5,
              altitude: 10,
              altitudeAccuracy: 1,
              heading: 0,
              headingAccuracy: 1,
              speed: 0,
              speedAccuracy: 1,
            ),
          );
        }

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              autoTriggerGps: false,
              reverseGeocodeService: mockGeocodeService,
              locationProvider: testLocationProvider,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Pengguna mengetuk tombol GPS FAB
        await tester.tap(find.byType(AppFab));
        await tester.pumpAndSettle();

        // Modal lembar bawah muncul karena GPS mati
        expect(find.text('Layanan lokasi belum diaktifkan'), findsOneWidget);

        // Tombol konfirmasi dinonaktifkan
        final confirmFinder = find.widgetWithText(AppButton, 'Pilih titik ini');
        expect(
          tester.widget<AppButton>(confirmFinder).onPressed,
          isNull,
        );

        // Pengguna menyalakan sakelar GPS di Pengaturan OS dan kembali ke app
        isGpsTurnedOnInSettings = true;
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();

        // Verifikasi Self-Healing: GPS fix otomatis diperoleh, kamera berpindah
        expect(
          find.text('Koordinat: -6.175400, 106.827200'),
          findsOneWidget,
        );

        // Lembar galat otomatis tertutup setelah perolehan GPS berhasil
        expect(find.text('Layanan lokasi belum diaktifkan'), findsNothing);

        // Tombol konfirmasi sekarang otomatis aktif tanpa ketukan manual
        expect(
          tester.widget<AppButton>(confirmFinder).onPressed,
          isNotNull,
        );
      },
    );

    testWidgets(
      'automatically self-heals and dismisses modal sheet when GPS is '
      'toggled in Quick Settings panel (resumed -> inactive -> resumed)',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        var isGpsTurnedOnInQuickSettings = false;

        Future<LocationResult> testLocationProvider() async {
          if (!isGpsTurnedOnInQuickSettings) {
            return const LocationResult.serviceDisabled();
          }
          return LocationResult.success(
            Position(
              latitude: -6.1754,
              longitude: 106.8272,
              timestamp: DateTime.now(),
              accuracy: 5,
              altitude: 10,
              altitudeAccuracy: 1,
              heading: 0,
              headingAccuracy: 1,
              speed: 0,
              speedAccuracy: 1,
            ),
          );
        }

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              autoTriggerGps: false,
              reverseGeocodeService: mockGeocodeService,
              locationProvider: testLocationProvider,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Pengguna mengetuk tombol GPS FAB -> galat muncul
        await tester.tap(find.byType(AppFab));
        await tester.pumpAndSettle();

        expect(find.text('Layanan lokasi belum diaktifkan'), findsOneWidget);

        // 2. Pengguna mengusap bilah status (membuka panel Quick Settings)
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        await tester.pump();

        // 3. Pengguna mengaktifkan sakelar Lokasi di Quick Settings
        isGpsTurnedOnInQuickSettings = true;

        // 4. Pengguna menutup panel Quick Settings (kembali ke aplikasi)
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();

        // 5. Verifikasi Self-Healing: GPS fix otomatis diperoleh, kamera
        //    berpindah
        expect(
          find.text('Koordinat: -6.175400, 106.827200'),
          findsOneWidget,
        );

        // Lembar galat otomatis tertutup setelah perolehan GPS berhasil
        expect(find.text('Layanan lokasi belum diaktifkan'), findsNothing);

        final confirmFinder = find.widgetWithText(AppButton, 'Pilih titik ini');
        expect(
          tester.widget<AppButton>(confirmFinder).onPressed,
          isNotNull,
        );
      },
    );

    testWidgets(
      'preserves existing bottom sheet without duplicate instantiation when '
      'Quick Settings is closed without enabling GPS, and recovers '
      'on subsequent toggle',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        var isGpsTurnedOn = false;

        Future<LocationResult> testLocationProvider() async {
          if (!isGpsTurnedOn) {
            return const LocationResult.serviceDisabled();
          }
          return LocationResult.success(
            Position(
              latitude: -6.1754,
              longitude: 106.8272,
              timestamp: DateTime.now(),
              accuracy: 5,
              altitude: 10,
              altitudeAccuracy: 1,
              heading: 0,
              headingAccuracy: 1,
              speed: 0,
              speedAccuracy: 1,
            ),
          );
        }

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              autoTriggerGps: false,
              reverseGeocodeService: mockGeocodeService,
              locationProvider: testLocationProvider,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(AppFab));
        await tester.pumpAndSettle();
        expect(find.text('Layanan lokasi belum diaktifkan'), findsOneWidget);

        // Pengguna membuka Quick Settings tetapi TIDAK menyalakan GPS
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        await tester.pump();
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();

        // Lembar galat tetap satu (tidak ada duplikasi modal)
        expect(find.text('Layanan lokasi belum diaktifkan'), findsOneWidget);

        // Pengguna membuka Quick Settings kedua kalinya dan menyalakan GPS
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        await tester.pump();
        isGpsTurnedOn = true;
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();

        // Galat otomatis tertutup dan lokasi diperoleh
        expect(find.text('Layanan lokasi belum diaktifkan'), findsNothing);
        expect(
          find.text('Koordinat: -6.175400, 106.827200'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'does not trigger auto-recovery on resume if user has manually '
      'interacted with map, protecting manual coordinates',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        var isGpsTurnedOnInSettings = false;
        var gpsCallCount = 0;

        Future<LocationResult> testLocationProvider() async {
          gpsCallCount++;
          if (!isGpsTurnedOnInSettings) {
            return const LocationResult.serviceDisabled();
          }
          return LocationResult.success(
            Position(
              latitude: -6.1754,
              longitude: 106.8272,
              timestamp: DateTime.now(),
              accuracy: 5,
              altitude: 10,
              altitudeAccuracy: 1,
              heading: 0,
              headingAccuracy: 1,
              speed: 0,
              speedAccuracy: 1,
            ),
          );
        }

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              autoTriggerGps: false,
              reverseGeocodeService: mockGeocodeService,
              locationProvider: testLocationProvider,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Pengguna mengetuk tombol GPS FAB -> galat muncul
        await tester.tap(find.byType(AppFab));
        await tester.pumpAndSettle();
        expect(gpsCallCount, equals(1));
        expect(find.text('Layanan lokasi belum diaktifkan'), findsOneWidget);

        // 2. Pengguna menutup lembar galat dengan menekan "Pilih manual"
        await tester.tap(find.widgetWithText(AppButton, 'Pilih manual'));
        await tester.pumpAndSettle();
        expect(find.text('Layanan lokasi belum diaktifkan'), findsNothing);

        // 3. Pengguna menggeser peta secara manual
        await tester.drag(find.byType(FlutterMap), const Offset(0, -100));
        await tester.pumpAndSettle();

        final manualCoordFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data?.startsWith('Koordinat:') ?? false),
        );
        final manualCoordText =
            tester.widget<Text>(manualCoordFinder).data;

        // 4. Aplikasi berpindah ke background dan kembali
        isGpsTurnedOnInSettings = true;
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();

        // 5. Verifikasi: GPS TIDAK dipanggil lagi dan koordinat manual tidak
        //    tertimpa
        expect(gpsCallCount, equals(1));
        expect(
          tester.widget<Text>(manualCoordFinder).data,
          equals(manualCoordText),
        );
      },
    );

    testWidgets(
      'concurrency guard: ignores duplicate calls when GPS locating is busy',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        final slowCompleter = Completer<LocationResult>();
        var callCount = 0;

        Future<LocationResult> testLocationProvider() {
          callCount++;
          return slowCompleter.future;
        }

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              autoTriggerGps: false,
              reverseGeocodeService: mockGeocodeService,
              locationProvider: testLocationProvider,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Panggilan GPS pertama (sedang berjalan)
        await tester.tap(find.byType(AppFab));
        await tester.pump();
        expect(callCount, equals(1));

        // 2. Ketukan kedua saat masih busy-lock (isLocatingUser == true)
        await tester.tap(find.byType(AppFab));
        await tester.pump();
        expect(callCount, equals(1));

        slowCompleter.complete(
          const LocationResult.serviceDisabled(),
        );
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'cancels in-flight reverse geocode request when dialog is disposed',
      (tester) async {
        final geocodeCompleter = Completer<ReverseGeocodeResult>();
        AppCancellationToken? capturedToken;

        when(
          () => mockGeocodeService.reverseGeocode(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((invocation) {
          capturedToken =
              invocation.namedArguments[#cancelToken] as AppCancellationToken?;
          return geocodeCompleter.future;
        });

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              initialLatitude: -6.2088,
              initialLongitude: 106.8456,
              reverseGeocodeService: mockGeocodeService,
            ),
          ),
        );
        // Biarkan debounce timer (650ms) selesai dan memicu geocode
        await tester.pump(const Duration(milliseconds: 700));

        expect(capturedToken, isNotNull);
        expect(capturedToken!.isCancelled, isFalse);

        // Unmount widget (dispose dialog)
        await tester.pumpWidget(
          buildTestableWidget(const SizedBox.shrink()),
        );

        // Verifikasi cancelToken dibatalkan saat dialog di-dispose
        expect(capturedToken!.isCancelled, isTrue);

        geocodeCompleter.complete(
          const ReverseGeocodeResult.cancelled(
            latitude: -6.2088,
            longitude: 106.8456,
          ),
        );
      },
    );

    testWidgets(
      'manually dismissing error bottom sheet via "Pilih manual" prevents '
      'auto-recovery from re-triggering GPS or reopening error sheet on resume',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        var gpsCallCount = 0;
        Future<LocationResult> testLocationProvider() async {
          gpsCallCount++;
          return const LocationResult.serviceDisabled();
        }

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              autoTriggerGps: false,
              reverseGeocodeService: mockGeocodeService,
              locationProvider: testLocationProvider,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Ketuk tombol GPS FAB -> galat muncul
        await tester.tap(find.byType(AppFab));
        await tester.pumpAndSettle();
        expect(gpsCallCount, equals(1));
        expect(find.text('Layanan lokasi belum diaktifkan'), findsOneWidget);

        // 2. Pengguna menutup lembar galat secara manual dengan "Pilih manual"
        await tester.tap(find.widgetWithText(AppButton, 'Pilih manual'));
        await tester.pumpAndSettle();
        expect(find.text('Layanan lokasi belum diaktifkan'), findsNothing);

        // 3. Aplikasi beralih ke background dan kembali aktif (resumed)
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();

        // 4. Verifikasi: GPS TIDAK dipanggil lagi dan lembar galat TIDAK muncul
        expect(gpsCallCount, equals(1));
        expect(find.text('Layanan lokasi belum diaktifkan'), findsNothing);
      },
    );

    testWidgets(
      'automatically self-heals and dismisses modal sheet on resume even when '
      'dialog was initialized with initial coordinates',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        var isGpsTurnedOn = false;
        Future<LocationResult> testLocationProvider() async {
          if (!isGpsTurnedOn) {
            return const LocationResult.serviceDisabled();
          }
          return LocationResult.success(
            Position(
              latitude: -6.1754,
              longitude: 106.8272,
              timestamp: DateTime.now(),
              accuracy: 5,
              altitude: 10,
              altitudeAccuracy: 1,
              heading: 0,
              headingAccuracy: 1,
              speed: 0,
              speedAccuracy: 1,
            ),
          );
        }

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              initialLatitude: -6.2088,
              initialLongitude: 106.8456,
              initialAddress: 'Jl. Sudirman No. 1',
              reverseGeocodeService: mockGeocodeService,
              locationProvider: testLocationProvider,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Ketuk tombol GPS FAB saat koordinat awal ada tapi GPS mati
        await tester.tap(find.byType(AppFab));
        await tester.pumpAndSettle();
        expect(find.text('Layanan lokasi belum diaktifkan'), findsOneWidget);

        // 2. GPS diaktifkan di Pengaturan OS dan aplikasi resume
        isGpsTurnedOn = true;
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();

        // 3. Verifikasi: Lembar galat otomatis tertutup dan koordinat
        //    diperbarui
        expect(find.text('Layanan lokasi belum diaktifkan'), findsNothing);
        expect(
          find.text('Koordinat: -6.175400, 106.827200'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'presents preciseLocationRequired bottom sheet and auto-heals on resume',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        var isPreciseGranted = false;
        Future<LocationResult> testLocationProvider() async {
          if (!isPreciseGranted) {
            return const LocationResult.preciseLocationRequired();
          }
          return LocationResult.success(
            Position(
              latitude: -6.1754,
              longitude: 106.8272,
              timestamp: DateTime.now(),
              accuracy: 5,
              altitude: 10,
              altitudeAccuracy: 1,
              heading: 0,
              headingAccuracy: 1,
              speed: 0,
              speedAccuracy: 1,
            ),
          );
        }

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              initialLatitude: -6.2088,
              initialLongitude: 106.8456,
              initialAddress: 'Jl. Sudirman No. 1',
              reverseGeocodeService: mockGeocodeService,
              locationProvider: testLocationProvider,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Ketuk tombol GPS FAB saat hanya memiliki izin approximate
        await tester.tap(find.byType(AppFab));
        await tester.pumpAndSettle();
        expect(find.text('Akses lokasi presisi diperlukan'), findsOneWidget);
        expect(find.text('Buka pengaturan'), findsOneWidget);

        // 2. Izin presisi diaktifkan pengguna di Pengaturan OS lalu resume
        isPreciseGranted = true;
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();

        // 3. Verifikasi: Lembar galat otomatis tertutup dan posisi diperbarui
        expect(find.text('Akses lokasi presisi diperlukan'), findsNothing);
        expect(
          find.text('Koordinat: -6.175400, 106.827200'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'immediately triggers reverse geocoding on initial coordinates '
      'without delay when initialAddress is null',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        final completer = Completer<ReverseGeocodeResult>();
        when(
          () => mockGeocodeService.reverseGeocode(
            latitude: -6.2088,
            longitude: 106.8456,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) => completer.future);

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              initialLatitude: -6.2088,
              initialLongitude: 106.8456,
              reverseGeocodeService: mockGeocodeService,
            ),
          ),
        );
        // Single pump (first frame): reverse geocode must already be triggered
        await tester.pump();
        expect(findAddressShimmer(), findsOneWidget);
        verify(
          () => mockGeocodeService.reverseGeocode(
            latitude: -6.2088,
            longitude: 106.8456,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);

        // Resolve geocoding
        completer.complete(
          const ReverseGeocodeResult.success(
            latitude: -6.2088,
            longitude: 106.8456,
            address: 'Jl. Merdeka No. 45',
          ),
        );
        await tester.pumpAndSettle();

        expect(findAddressShimmer(), findsNothing);
        expect(find.text('Jl. Merdeka No. 45'), findsOneWidget);
      },
    );

    testWidgets(
      'immediately triggers reverse geocoding on initial coordinates '
      'when initialAddress is empty string or whitespace',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        when(
          () => mockGeocodeService.reverseGeocode(
            latitude: -6.2088,
            longitude: 106.8456,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => const ReverseGeocodeResult.success(
            latitude: -6.2088,
            longitude: 106.8456,
            address: 'Jl. Sudirman No. 10',
          ),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              initialLatitude: -6.2088,
              initialLongitude: 106.8456,
              initialAddress: '   ',
              reverseGeocodeService: mockGeocodeService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Jl. Sudirman No. 10'), findsOneWidget);
        verify(
          () => mockGeocodeService.reverseGeocode(
            latitude: -6.2088,
            longitude: 106.8456,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'automatically triggers GPS search on open when without initial '
      'coordinates and locks location',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        final dummyGpsPosition = Position(
          latitude: -6.1754,
          longitude: 106.8272,
          timestamp: DateTime.now(),
          accuracy: 5,
          altitude: 10,
          altitudeAccuracy: 1,
          heading: 0,
          headingAccuracy: 1,
          speed: 0,
          speedAccuracy: 1,
        );

        when(
          () => mockGeocodeService.reverseGeocode(
            latitude: -6.1754,
            longitude: 106.8272,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => const ReverseGeocodeResult.success(
            latitude: -6.1754,
            longitude: 106.8272,
            address: 'Jl. Monas No. 1',
          ),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              reverseGeocodeService: mockGeocodeService,
              locationProvider: () async =>
                  LocationResult.success(dummyGpsPosition),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verifikasi bahwa titik GPS berhasil dikunci dan tombol aktif
        expect(
          find.text('Koordinat: -6.175400, 106.827200'),
          findsOneWidget,
        );
        expect(find.text('Jl. Monas No. 1'), findsOneWidget);
        final confirmButton = tester.widget<AppButton>(
          find.widgetWithText(AppButton, 'Pilih titik ini'),
        );
        expect(confirmButton.onPressed, isNotNull);
        expect(
          find.text('Geser peta untuk menentukan titik secara manual'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'automatically triggers GPS and presents error bottom sheet when GPS is '
      'disabled on open',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        await tester.pumpWidget(
          buildTestableWidget(
            AppMapPickerDialog(
              reverseGeocodeService: mockGeocodeService,
              locationProvider: () async =>
                  const LocationResult.serviceDisabled(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Lembar galat otomatis muncul karena GPS terpicu otomatis pada open
        expect(find.text('Layanan lokasi belum diaktifkan'), findsOneWidget);
        expect(find.text('Aktifkan lokasi'), findsOneWidget);
        expect(find.text('Pilih manual'), findsOneWidget);

        // Pengguna mengetuk "Pilih manual" untuk menutup error sheet
        await tester.tap(find.text('Pilih manual'));
        await tester.pumpAndSettle();

        expect(find.text('Layanan lokasi belum diaktifkan'), findsNothing);
        expect(
          find.text('Geser peta untuk menentukan titik secara manual'),
          findsOneWidget,
        );
      },
    );
  });
}
